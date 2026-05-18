@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: =====================================================================
:: TRTC AI Customer Service - One-click Launcher (Windows)
:: TRTC AI 智能客服 - 一键启动脚本 (Windows)
::
:: Features / 功能：
::   1. Auto-detect Python version (>= 3.8) / 自动检测 Python 版本
::   2. Auto-create env.yaml from env.example.yaml / 自动生成配置文件
::   3. Auto-create & activate venv / 自动创建虚拟环境
::   4. Auto-install dependencies / 自动安装依赖
::   5. Default PyPI, fallback Tsinghua mirror / 默认官方源，回退清华镜像
::   6. Auto-detect locale for i18n output / 根据系统语言自动切换提示
::   7. Support --https self-signed cert / 支持 HTTPS 自签证书
::   8. Launch Flask server / 启动 Flask 服务
::
:: Usage / 使用：
::   start.bat               Start (HTTP) / 启动
::   start.bat --https       Start (HTTPS) / 启动 HTTPS 模式
::   start.bat --rebuild     Force rebuild venv / 强制重建虚拟环境
:: =====================================================================

cd /d "%~dp0"

set VENV_DIR=venv
set VENV_PY=%VENV_DIR%\Scripts\python.exe
set VENV_PIP=%VENV_DIR%\Scripts\pip.exe
set ENV_FILE=env.yaml
set ENV_EXAMPLE=env.example.yaml
set REQUIREMENTS=requirements.txt
set PORT=8080
set USE_HTTPS=0
set REBUILD=0

:: ============ Locale Detection / 语言检测 ============
set IS_ZH=0
for /f "tokens=3" %%a in ('reg query "HKCU\Control Panel\International" /v LocaleName 2^>nul ^| findstr /i "LocaleName"') do (
    echo %%a | findstr /i "^zh" >nul 2>&1 && set IS_ZH=1
)

:: Argument parsing / 解析参数
for %%a in (%*) do (
    if "%%a"=="--https" set USE_HTTPS=1
    if "%%a"=="--rebuild" set REBUILD=1
    if "%%a"=="--help" goto :show_help
    if "%%a"=="-h" goto :show_help
)

:: ============ Step 1: Detect Python / 检测 Python ============
if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 检测 Python 环境...) else (echo [%TIME:~0,8%] Detecting Python environment...)

set PY_CMD=
for %%p in (python3 python) do (
    if not defined PY_CMD (
        %%p --version >nul 2>&1 && (
            for /f "tokens=*" %%v in ('%%p -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2^>nul') do (
                for /f "tokens=1,2 delims=." %%a in ("%%v") do (
                    if %%a GEQ 3 if %%b GEQ 8 (
                        set PY_CMD=%%p
                        if "%IS_ZH%"=="1" (echo √ 找到 Python %%v) else (echo √ Found Python %%v)
                    )
                )
            )
        )
    )
)

if not defined PY_CMD (
    if "%IS_ZH%"=="1" (
        echo × 未检测到 Python ^>= 3.8
        echo   请前往 https://www.python.org/downloads/ 下载安装
        echo   安装时务必勾选 "Add Python to PATH"
    ) else (
        echo × Python ^>= 3.8 not found
        echo   Please visit https://www.python.org/downloads/ to install
        echo   Make sure to check "Add Python to PATH" during installation
    )
    pause
    exit /b 1
)

:: ============ Step 2: Detect env.yaml / 检测 env.yaml ============
if not exist "%ENV_FILE%" (
    if not exist "%ENV_EXAMPLE%" (
        if "%IS_ZH%"=="1" (echo × 未找到 %ENV_EXAMPLE%，项目文件不完整) else (echo × %ENV_EXAMPLE% not found, project files incomplete)
        pause
        exit /b 1
    )
    copy "%ENV_EXAMPLE%" "%ENV_FILE%" >nul
    if "%IS_ZH%"=="1" (echo ⚠ 已创建 %ENV_FILE%（从 %ENV_EXAMPLE% 复制）) else (echo ⚠ Created %ENV_FILE% ^(copied from %ENV_EXAMPLE%^))
    echo.
    if "%IS_ZH%"=="1" (
        echo ╔══════════════════════════════════════════════════╗
        echo ║          首次配置 - 请编辑 env.yaml              ║
        echo ╚══════════════════════════════════════════════════╝
        echo.
        echo   请选择部署区域:
        echo     1^) 国际站 intl（默认）  2^) 中国站 cn
    ) else (
        echo ╔══════════════════════════════════════════════════╗
        echo ║       First-time Setup - Edit env.yaml          ║
        echo ╚══════════════════════════════════════════════════╝
        echo.
        echo   Choose deployment region:
        echo     1^) International ^(default^)  2^) China Mainland
    )
    set /p REGION_CHOICE="  [1-2]: "
    set DEPLOY_REGION=intl
    if "!REGION_CHOICE!"=="2" set DEPLOY_REGION=cn
    echo.
    if "%DEPLOY_REGION%"=="cn" (
        if "%IS_ZH%"=="1" (echo √ 部署区域: 中国站 ^(cn^)) else (echo √ Region: China Mainland ^(cn^))
        echo.
        if "%IS_ZH%"=="1" (
            echo   请用文本编辑器打开 %ENV_FILE% 填入以下密钥：
            echo.
            echo   [1/3] 腾讯云 API 密钥
            echo         获取: https://console.cloud.tencent.com/cam/capi
            echo         填入: CloudAPI.SECRET_ID / SECRET_KEY
            echo.
            echo   [2/3] TRTC 应用凭据
            echo         获取: https://console.cloud.tencent.com/trtc/app
            echo         填入: TRTC.SDKAPPID / SECRET
            echo.
            echo   [3/3] LLM API Key
            echo         配置指南: https://cloud.tencent.com/document/product/647/115413
            echo         填入: LLMConfig.APIKey / APIUrl / Model
        ) else (
            echo   Open %ENV_FILE% with a text editor and fill in:
            echo.
            echo   [1/3] Tencent Cloud API Credentials
            echo         Get from: https://console.cloud.tencent.com/cam/capi
            echo         Fill in: CloudAPI.SECRET_ID / SECRET_KEY
            echo.
            echo   [2/3] TRTC App Credentials
            echo         Get from: https://console.cloud.tencent.com/trtc/app
            echo         Fill in: TRTC.SDKAPPID / SECRET
            echo.
            echo   [3/3] LLM API Key
            echo         Config guide: https://cloud.tencent.com/document/product/647/115413
            echo         Fill in: LLMConfig.APIKey / APIUrl / Model
        )
    ) else (
        if "%IS_ZH%"=="1" (echo √ 部署区域: 国际站 ^(intl^)) else (echo √ Region: International ^(intl^))
        echo.
        if "%IS_ZH%"=="1" (
            echo   请用文本编辑器打开 %ENV_FILE% 填入以下密钥：
            echo.
            echo   [1/3] 腾讯云 API 密钥
            echo         获取: https://console.intl.cloud.tencent.com/cam/capi
            echo         填入: CloudAPI.SECRET_ID / SECRET_KEY
            echo.
            echo   [2/3] TRTC 应用凭据
            echo         获取: https://console.trtc.io/app
            echo         填入: TRTC.SDKAPPID / SECRET
            echo.
            echo   [3/3] LLM API Key
            echo         配置指南: https://trtc.io/document/68338?product=conversationalai
            echo         填入: LLMConfig.APIKey / APIUrl / Model
        ) else (
            echo   Open %ENV_FILE% with a text editor and fill in:
            echo.
            echo   [1/3] Tencent Cloud API Credentials
            echo         Get from: https://console.intl.cloud.tencent.com/cam/capi
            echo         Fill in: CloudAPI.SECRET_ID / SECRET_KEY
            echo.
            echo   [2/3] TRTC App Credentials
            echo         Get from: https://console.trtc.io/app
            echo         Fill in: TRTC.SDKAPPID / SECRET
            echo.
            echo   [3/3] LLM API Key
            echo         Config guide: https://trtc.io/document/68338?product=conversationalai
            echo         Fill in: LLMConfig.APIKey / APIUrl / Model
        )
    )
    echo.
    if "%IS_ZH%"=="1" (echo   填写完成后重新运行 start.bat) else (echo   Re-run start.bat after filling in credentials)
    echo.
    pause
    exit /b 0
)
if "%IS_ZH%"=="1" (echo √ %ENV_FILE% 已存在) else (echo √ %ENV_FILE% exists)

:: Check for unfilled placeholders / 检测未填的占位符
findstr /C:"your-secret-id" /C:"your-secret-key" /C:"your-trtc-secret" /C:"your-llm-api-key" /C:"your-model-name" /C:"your-llm-api-url" "%ENV_FILE%" >nul 2>&1
if %errorlevel%==0 (
    if "%IS_ZH%"=="1" (
        echo ⚠ 检测到 %ENV_FILE% 中部分密钥未填写
        echo   请编辑 %ENV_FILE% 补全密钥后重新运行
    ) else (
        echo ⚠ Some credentials in %ENV_FILE% are not filled in
        echo   Please edit %ENV_FILE% and re-run
    )
    pause
    exit /b 0
)

:: ============ Step 3: Virtual Environment / 虚拟环境 ============
if "%REBUILD%"=="1" if exist "%VENV_DIR%" (
    if "%IS_ZH%"=="1" (echo ⚠ 强制重建：删除现有 %VENV_DIR%...) else (echo ⚠ Force rebuild: removing %VENV_DIR%...)
    rmdir /s /q "%VENV_DIR%"
)

if not exist "%VENV_DIR%" (
    if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 创建虚拟环境 %VENV_DIR%...) else (echo [%TIME:~0,8%] Creating virtual environment %VENV_DIR%...)
    %PY_CMD% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        if "%IS_ZH%"=="1" (echo × venv 创建失败) else (echo × venv creation failed)
        pause
        exit /b 1
    )
    if "%IS_ZH%"=="1" (echo √ 虚拟环境创建完成) else (echo √ Virtual environment created)
    set NEED_INSTALL=1
) else (
    if "%IS_ZH%"=="1" (echo √ 虚拟环境已存在) else (echo √ Virtual environment exists)
    set NEED_INSTALL=0
)

:: ============ Step 4: Check Dependencies / 检测依赖 ============
if "%NEED_INSTALL%"=="0" (
    "%VENV_PY%" -c "import flask, envyaml, loguru, tencentcloud, TLSSigAPIv2" >nul 2>&1
    if errorlevel 1 (
        if "%IS_ZH%"=="1" (echo ⚠ 检测到依赖缺失，准备安装...) else (echo ⚠ Missing dependencies detected, preparing to install...)
        set NEED_INSTALL=1
    )
)

if "%NEED_INSTALL%"=="1" (
    if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 安装依赖...) else (echo [%TIME:~0,8%] Installing dependencies...)
    "%VENV_PIP%" install --upgrade pip >nul 2>&1

    :: Default: official PyPI; fallback: Tsinghua mirror
    "%VENV_PIP%" install -r "%REQUIREMENTS%" --timeout 30 >nul 2>&1
    if errorlevel 1 (
        if "%IS_ZH%"=="1" (echo ⚠ 官方源失败，切换到清华镜像重试...) else (echo ⚠ PyPI failed, retrying with Tsinghua mirror...)
        "%VENV_PIP%" install -r "%REQUIREMENTS%" -i https://pypi.tuna.tsinghua.edu.cn/simple --timeout 15
        if errorlevel 1 (
            if "%IS_ZH%"=="1" (echo × 依赖安装失败) else (echo × Dependency installation failed)
            pause
            exit /b 1
        )
        if "%IS_ZH%"=="1" (echo √ 依赖安装完成（via 清华镜像）) else (echo √ Dependencies installed ^(via Tsinghua mirror^))
    ) else (
        if "%IS_ZH%"=="1" (echo √ 依赖安装完成（via 官方源）) else (echo √ Dependencies installed ^(via PyPI^))
    )
) else (
    if "%IS_ZH%"=="1" (echo √ 依赖已就绪) else (echo √ Dependencies ready)
)

:: ============ Step 5: Port Conflict / 端口冲突检测 ============
if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 检查端口 %PORT% 是否被占用...) else (echo [%TIME:~0,8%] Checking if port %PORT% is in use...)
for /f "tokens=5" %%p in ('netstat -ano 2^>nul ^| findstr ":%PORT% " ^| findstr "LISTENING"') do (
    if "%IS_ZH%"=="1" (echo ⚠ 端口 %PORT% 已被占用 ^(PID: %%p^)) else (echo ⚠ Port %PORT% in use ^(PID: %%p^))
    if "%IS_ZH%"=="1" (set /p REPLY="  是否终止该进程并继续启动？[Y/n] ") else (set /p REPLY="  Kill the process and continue? [Y/n] ")
    if /i "!REPLY!"=="" set REPLY=y
    if /i "!REPLY!"=="y" (
        taskkill /PID %%p /F >nul 2>&1
        timeout /t 1 /nobreak >nul
        if "%IS_ZH%"=="1" (echo √ 已终止占用端口的进程) else (echo √ Killed process occupying port)
    ) else (
        if "%IS_ZH%"=="1" (echo × 端口 %PORT% 被占用，请手动释放后重试) else (echo × Port %PORT% is occupied, please free it and retry)
        pause
        exit /b 1
    )
)

:: ============ Step 6: Auto-detect public network / 公网环境检测 ============
set PUBLIC_IP=
set AUTO_HTTPS=0
set EXPLICIT_HTTPS=%USE_HTTPS%

:: Try to detect public IP via curl
where curl >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('curl -s --max-time 3 https://ifconfig.me 2^>nul') do set PUBLIC_IP=%%i
)

:: Auto-enable HTTPS if public IP detected and --https was not explicitly passed
if "%EXPLICIT_HTTPS%"=="0" if defined PUBLIC_IP (
    echo !PUBLIC_IP! | findstr /r "^[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$" >nul 2>&1
    if not errorlevel 1 (
        if not "!PUBLIC_IP!"=="127.0.0.1" (
            if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 检测到公网 IP: !PUBLIC_IP!，自动启用 HTTPS) else (echo [%TIME:~0,8%] Public IP detected: !PUBLIC_IP!, auto-enabling HTTPS)
            set USE_HTTPS=1
            set AUTO_HTTPS=1
        )
    )
)

:: ============ Step 7: HTTPS Self-signed Cert / HTTPS 自签证书 ============
set CERT_DIR=certs
set CERT_FILE=%CERT_DIR%\cert.pem
set KEY_FILE=%CERT_DIR%\key.pem

if "%USE_HTTPS%"=="1" (
    if "%IS_ZH%"=="1" (echo [%TIME:~0,8%] 准备 HTTPS 证书...) else (echo [%TIME:~0,8%] Preparing HTTPS certificate...)
    if exist "%CERT_FILE%" if exist "%KEY_FILE%" (
        if "%IS_ZH%"=="1" (echo √ 已有证书: %CERT_FILE%) else (echo √ Certificate found: %CERT_FILE%)
    ) else (
        where openssl >nul 2>&1
        if errorlevel 1 (
            if "%AUTO_HTTPS%"=="1" (
                if "%IS_ZH%"=="1" (echo ⚠ openssl 未安装，回退到 HTTP 模式) else (echo ⚠ openssl not found, falling back to HTTP)
                set USE_HTTPS=0
            ) else (
                if "%IS_ZH%"=="1" (
                    echo × openssl 未安装，无法生成自签证书
                    echo   Windows 安装方式:
                ) else (
                    echo × openssl not installed, cannot generate self-signed cert
                    echo   Install on Windows:
                )
                echo     A: winget install ShiningLight.OpenSSL
                echo     B: https://slproweb.com/products/Win32OpenSSL.html
                pause
                exit /b 1
            )
        )
        if "%USE_HTTPS%"=="1" (
            if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"
            if "%IS_ZH%"=="1" (echo 生成自签证书（有效期 365 天）...) else (echo Generating self-signed certificate ^(valid 365 days^)...)
            openssl req -x509 -newkey rsa:2048 -nodes -keyout "%KEY_FILE%" -out "%CERT_FILE%" -days 365 -subj "/CN=localhost" 2>nul
            if "%IS_ZH%"=="1" (echo √ 证书已生成: %CERT_DIR%\) else (echo √ Certificate generated: %CERT_DIR%\)
            echo.
            if "%IS_ZH%"=="1" (
                echo ⚠ 这是自签证书，浏览器首次访问会提示"不安全"
                echo   解决方法: 点击"高级" → "继续前往"即可正常使用
            ) else (
                echo ⚠ Self-signed certificate: browser will show a security warning.
                echo   Click "Advanced" → "Proceed" to continue.
            )
            echo.
        )
    )
)

:: ============ Step 8: Launch / 启动 ============
echo.
echo ════════════════════════════════════════════════
if "%IS_ZH%"=="1" (echo   🚀 启动 TRTC AI 智能客服) else (echo   🚀 Launching TRTC AI Customer Service)
echo ════════════════════════════════════════════════
set PROTO=http
if "%USE_HTTPS%"=="1" set PROTO=https
if defined PUBLIC_IP if not "%PUBLIC_IP%"=="127.0.0.1" (
    if "%IS_ZH%"=="1" (echo    公网: %PROTO%://!PUBLIC_IP!:%PORT%) else (echo    Public: %PROTO%://!PUBLIC_IP!:%PORT%)
    if "%IS_ZH%"=="1" (echo    本地: %PROTO%://localhost:%PORT%) else (echo    Local:  %PROTO%://localhost:%PORT%)
) else (
    if "%IS_ZH%"=="1" (echo    访问: %PROTO%://localhost:%PORT%) else (echo    Visit: %PROTO%://localhost:%PORT%)
)
if "%IS_ZH%"=="1" (echo    停止: Ctrl+C) else (echo    Stop: Ctrl+C)
echo ════════════════════════════════════════════════
echo.

if "%USE_HTTPS%"=="1" (
    "%VENV_PY%" app.py --https
) else (
    "%VENV_PY%" app.py
)
goto :eof

:: ============ Help / 帮助 ============
:show_help
if "%IS_ZH%"=="1" (
    echo 用法: start.bat [--https] [--rebuild]
    echo   --https    启用 HTTPS（自动生成自签证书，支持远程/公网访问）
    echo   --rebuild  删除现有 venv 并重建
) else (
    echo Usage: start.bat [--https] [--rebuild]
    echo   --https    Enable HTTPS ^(auto-generate self-signed cert^)
    echo   --rebuild  Delete existing venv and rebuild
)
exit /b 0
