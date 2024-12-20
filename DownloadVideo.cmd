@echo off
chcp 65001 > nul
setlocal

rem Define o caminho do diretório onde o script está localizado
set SCRIPT_DIR=%~dp0

rem Define o caminho do yt-dlp e do ffmpeg no diretório do script
set YTDLP_PATH=%SCRIPT_DIR%yt-dlp.exe
set FFMPEG_PATH=%SCRIPT_DIR%ffmpeg.exe

rem Mensagem de boas-vindas
echo =======================================
echo   YouTube Video Downloader (MP4)
echo   Desenvolvido por Elves Santos
echo =======================================
echo.
echo Este programa permite baixar vídeos do YouTube em formato MP4.
echo Pressione uma tecla para continuar...
pause > nul

rem Verifica se o yt-dlp está instalado no diretório do script
if not exist "%YTDLP_PATH%" (
    echo yt-dlp não encontrado, baixando yt-dlp...
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o "%YTDLP_PATH%"
    if %ERRORLEVEL% neq 0 (
        echo Falha ao baixar yt-dlp. Verifique sua conexão de internet.
        pause
        exit /b
    )
    echo yt-dlp baixado com sucesso.
) else (
    echo yt-dlp já está instaladot.
    rem Verifica se deseja atualizar o yt-dlp
    set /p update_yt="Deseja verificar se há atualizações para o yt-dlp? [S/N]: "
    if /I "%update_yt%"=="S" (
        echo Verificando atualizações para o yt-dlp...
        curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe -o "%YTDLP_PATH%"
        if %ERRORLEVEL% neq 0 (
            echo Falha ao atualizar yt-dlp. Verifique sua conexão de internet.
            pause
        ) else (
            echo yt-dlp atualizado com sucesso.
        )
    )
)

rem Verifica se o ffmpeg está instalado no diretório do script
if not exist "%FFMPEG_PATH%" (
    echo ffmpeg não encontrado. Tentando instalar usando winget...
    
    rem Verifica se o winget está disponível
    winget --version >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo winget não está disponível. Instale o winget manualmente ou verifique sua instalação.
        pause
        exit /b
    )

    rem Tenta instalar o ffmpeg com winget
    winget install --id Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
    if %ERRORLEVEL% neq 0 (
        echo Falha ao instalar o FFmpeg. Verifique sua conexão de internet.
        pause
        exit /b
    )

    rem Move o ffmpeg.exe para o diretório do script
    if exist "%PROGRAMFILES%\FFmpeg\bin\ffmpeg.exe" (
        move /Y "%PROGRAMFILES%\FFmpeg\bin\ffmpeg.exe" "%FFMPEG_PATH%"
        echo FFmpeg movido para %FFMPEG_PATH%.
    ) else (
        echo FFmpeg não encontrado no diretório esperado após a instalação. Verifique a instalação manualmente.
        pause
        exit /b
    )
) else (
    echo FFmpeg já está instalado.
)

rem Define o caminho da pasta de Downloads
set DOWNLOADS_PATH=%USERPROFILE%\Downloads

:main_menu
echo.
echo =======================================
echo   YouTube Video Downloader (MP4)
echo   Desenvolvido por Elves Santos
echo =======================================
echo Selecione uma opção:
echo 1 - Baixar um único vídeo
echo 2 - Baixar vídeos em lote
echo 3 - Exibir informações do programa
echo 4 - Sair
echo.
set /p option="Escolha 1, 2, 3 ou 4: "

if "%option%"=="1" goto download_single
if "%option%"=="2" goto download_batch
if "%option%"=="3" goto show_info
if "%option%"=="4" exit
goto main_menu

:show_info
echo =======================================
echo   Informações do Programa
echo   YouTube Video Downloader (MP4)
echo   Desenvolvido por Elves Santos
echo.
echo Este programa permite baixar vídeos do YouTube em formato MP4.
echo Você pode baixar um único vídeo ou múltiplos vídeos em lote.
echo Todos os vídeos serão salvos na pasta de Downloads do usuário.
echo.
echo Pressione uma tecla para retornar ao menu...
pause > nul
goto main_menu

:download_single
set /p url="Insira o URL do vídeo: "
if "%url%"=="" (
    echo URL não pode ser vazio. Tente novamente.
    pause
    goto download_single
)
echo Iniciando download do vídeo...
"%YTDLP_PATH%" "%url%" -f "best[ext=mp4]" -o "%DOWNLOADS_PATH%\%(title)s.mp4" --progress

rem Verifica se o download foi bem-sucedido
if %ERRORLEVEL% neq 0 (
    echo Falha no download do vídeo. Verifique o URL e tente novamente.
    pause
    goto main_menu
)

rem Renomeia o arquivo após o download para downloadvideo.mp4
call :rename_file "%DOWNLOADS_PATH%\%(title)s.mp4" "downloadvideo.mp4"
echo Download concluído. Retornando ao menu...
pause
goto main_menu

:download_batch
echo Iniciando modo de download em lote...
set "morelinks=Y"
set "urls="
:collect_urls
set /p url="Insira o URL do vídeo (ou deixe em branco para sair): "
if "%url%"=="" goto start_batch_download
set urls=%urls% "%url%"
set /p morelinks="Deseja adicionar mais vídeos? [S/N]: "
if /I "%morelinks%"=="S" goto collect_urls

:start_batch_download
if "%urls%"=="" goto no_urls_error

echo Iniciando download de vídeos...
for %%i in (%urls%) do (
    echo Baixando vídeo: %%i
    "%YTDLP_PATH%" "%%i" -f "best[ext=mp4]" -o "%DOWNLOADS_PATH%\%(title)s.mp4" --progress

    rem Verifica se o download foi bem-sucedido
    if %ERRORLEVEL% neq 0 (
        echo Falha no download do vídeo: %%i. Continuando com os próximos vídeos.
        goto continue_batch
    )

    rem Renomeia o arquivo após o download para downloadvideo.mp4
    call :rename_file "%DOWNLOADS_PATH%\%(title)s.mp4" "downloadvideo.mp4"
    
    :continue_batch
)

echo Downloads concluídos. Retornando ao menu...
pause
goto main_menu

:no_urls_error
echo Nenhum URL fornecido para download.
pause
goto main_menu

:rename_file
set "source_path=%~1"
set "desired_name=%~2"
set "base_name=%desired_name%"
set "target_path=%DOWNLOADS_PATH%\%desired_name%"

rem Inicializa o contador para verificar se o arquivo já existe
set "counter=0"

rem Verifica se o arquivo já existe e incrementa o contador se necessário
:check_file
if exist "%target_path%" (
    set /a counter+=1
    set "target_path=%DOWNLOADS_PATH%\%base_name% (%counter%).mp4"
    goto check_file
)

rem Renomeia o arquivo
if exist "%source_path%" (
    echo Renomeando "%source_path%" para "%target_path%"
    move /Y "%source_path%" "%target_path%"
) else (
    echo Arquivo de origem não encontrado: "%source_path%"
)
goto :eof

:end
echo Operação concluída. Arquivos salvos em: %DOWNLOADS_PATH%
pause
