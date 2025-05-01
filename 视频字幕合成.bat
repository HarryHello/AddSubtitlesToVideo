@echo off
setlocal enabledelayedexpansion

title 烧录字幕至视频 By HarryHelloo

echo.
echo 本程序由HarryHelloo制作
echo BiliBili关注space.bilibili.com/492049833
echo.

:startloop

set "FFMPEG=ffmpeg"

where ffmpeg >nul 2>&1
if %errorlevel% equ 0 (
    echo 使用环境变量默认的ffmpeg。
) else (
    echo 错误: ffmpeg未配置到环境变量中，请手动添加或指定完整路径。
    set /p "FFMPEG=请输入ffmpeg路径: "
    if not exist "%FFMPEG%" (
        echo 错误：ffmpeg文件不存在！
        :ffmpeploop
        set /p "FFMPEG=请重新输入ffmpeg路径: "
        if not exist "%FFMPEG%" (
            echo 错误：ffmpeg文件仍然不存在！
            goto ffmpeploop
        )
    )
)



echo.
echo 本程序将字幕烧录至视频中。
echo 请将字幕文件放置于本程序的同一目录。
echo.

:: 输入视频路径
set "VIDEO_PATH="
set /p "VIDEO_PATH=请输入视频文件路径: "
if not exist "%VIDEO_PATH%" (
    echo 错误：视频文件不存在！
    :videoloop
    echo.
    set /p "VIDEO_PATH=请重新输入视频文件路径: "
    if not exist "%VIDEO_PATH%" (
        echo 错误：视频文件仍然不存在！
        goto videoloop
    )
)
echo.

:: 输入字幕路径
set "SUBTITLE_PATH="
set /p "SUBTITLE_PATH=请输入字幕文件名: "
if not exist "%SUBTITLE_PATH%" (
    echo 错误：字幕文件不存在！请检查字幕文件是否位于同一目录！
    :subtitleloop
    echo.
    set /p "SUBTITLE_PATH=请重新输入字幕文件名: "
    if not exist "%SUBTITLE_PATH%" (
        echo 错误：字幕文件仍然不存在！请检查字幕文件是否位于同一目录！
        goto subtitleloop
    )
)
echo.

:: 输入输出路径
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" ^| findstr "Videos"') do (
    set VIDEO_FOLDER=%%b
)

if not defined VIDEO_FOLDER (
    echo 无法获取默认视频文件夹。
    goto :customPath
) else if "%VIDEO_FOLDER%"=="" (
    echo 无法获取默认视频文件夹。
    goto :customPath
) else (
    echo 检测到默认视频文件夹路径为: %VIDEO_FOLDER%
    set "OUTPUT_DIR=%VIDEO_FOLDER%\Output"
    choice /c YN /n /m "是否使用默认视频文件夹作为输出目录？(Y/N): "
    if errorlevel 2 (
        goto :customPath
    ) else (
        echo 使用默认视频文件夹作为输出目录。
        echo.
        goto :checkDir
    )
)

:customPath
echo.
set /p "OUTPUT_DIR=请输入要输出的目录路径: "

:checkDir
:: 检查路径是否存在，如果不存在则创建
if not exist "%OUTPUT_DIR%" (
    echo 文件夹不存在，正在创建...
    echo 创建输出文件夹: "%OUTPUT_DIR%"
    md "%OUTPUT_DIR%"
    if exist "%OUTPUT_DIR%" (
        echo 文件夹已成功创建。
    ) else (
        echo 错误：无法创建文件夹，请检查权限或路径合法性。
        choice /c YN /n /m "是否重新输入输出目录？(Y/N): "
        if errorlevel 2 (
            echo.
            echo 退出程序...
            echo.
            pause
            exit /b
        )else (
            goto :customPath
        )
    )
)

set "OUTPUT_FILE_NAME="
set /p "OUTPUT_FILE_NAME=请输入要输出的文件名: "
set "OUTPUT_PATH=%OUTPUT_DIR%\%OUTPUT_FILE_NAME%"


:fileloop
echo.
echo 设置路径为%OUTPUT_PATH%
echo.

if exist "%OUTPUT_PATH%" (
    echo 警告：文件已存在。
    choice /c YN /n /m "是否覆盖？(Y/N): "
    if errorlevel 2 (
        echo 操作已取消。
        echo.
        choice /c YN /n /m "是否重新输入输出文件名？(Y/N): "
        if errorlevel 2 (
            echo 退出程序。
            echo.
            pause
            exit /b  
        ) else (
            set /p "OUTPUT_FILE_NAME=请重新输入输出文件名: "
            set "OUTPUT_PATH=%OUTPUT_DIR%\%OUTPUT_FILE_NAME%"
            goto fileloop
        )
    ) else (
        echo 覆盖已有文件...
    )
) else (
    echo 创建新文件...
)


echo.
echo 将输出到%OUTPUT_PATH%
echo.
set "QUALITY=23"
echo "请输入视频质量 (18~28, 数字越小质量越好,速度越慢)"
set /p "QUALITY=默认为23: "

if not defined QUALITY (
    echo 使用默认值。
    set "QUALITY=23"
) else if "%QUALITY%"=="" (
    echo 使用默认值。
    set "QUALITY=23"
) else (
    echo 设置质量为%QUALITY%
)

echo.
echo 正在处理，请稍等...
echo.

:: 调用 FFmpeg 命令
"%FFMPEG%" -y ^
-i "%VIDEO_PATH%" ^
-vf ass="%SUBTITLE_PATH%" ^
-c:a copy ^
-c:v libx264 ^
-preset fast ^
-crf %QUALITY% ^
-pix_fmt yuv420p ^
"%OUTPUT_PATH%" 

if %errorlevel% equ 0 (
    echo.
    echo 处理完成！
    echo.
    pause
    exit /b
) else (
    echo.
    echo 错误: ffmpeg执行失败, 退出码为 %errorlevel%。
    choice /c YN /n /m "是否重新尝试？(Y/N): "
    if errorlevel 2 (
        echo.
        echo 退出程序...
        echo.
        pause
        exit /b
    ) else (
        echo.
        echo 重新尝试...
        echo.
        "%FFMPEG%" -y ^
        -i "%VIDEO_PATH%" ^
        -vf ass="%SUBTITLE_PATH%" ^
        -c:a copy ^
        -c:v libx264 ^
        -preset fast ^
        -crf %QUALITY% ^
        -pix_fmt yuv420p ^
        "%OUTPUT_PATH%" 
    )
)

if %errorlevel% equ 0 (
    echo.
    echo 处理完成！
    echo.
    pause
    exit /b
) else (
    echo.
    echo 失败。请检查文件和权限。
    echo.
    choice /c YN /n /m "是否回到开头重新尝试？(Y/N): "
    if errorlevel 1 (
        echo.
        echo ------------------------------
        echo.
        goto startloop
    )
)

echo.
echo 即将退出程序...
echo.
pause
exit /b