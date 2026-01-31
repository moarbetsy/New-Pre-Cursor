# setup-cursor

**What happens when you type `setup-cursor` and download it?**

You get a **complete, professional development environment** that transforms Windows + Cursor IDE into a streamlined coding workspace. One command gives you everything needed for modern Python/JavaScript development.

## 🚀 What You Get After Running `setup-cursor -Setup`

### ✅ **Complete Development Environment**
- **UV** (modern Python package manager) - replaces pip, faster and more reliable
- **Bun** (fast JavaScript runtime) - replaces Node.js/npm, 3x faster than npm
- **Git** (version control) - latest stable version
- **Python virtual environment** - automatically managed per project
- **All dependencies** - installed and ready to use

### ✅ **Cursor IDE Optimization**
- **Clean project explorer** - only shows your `src/` folder, hides all tooling
- **PowerShell 7** as default terminal with optimized settings
- **IntelliSense** configured for Python, JavaScript, and PowerShell
- **Auto-formatting** on save with proper code style
- **Stable extensions** - PowerShell extension configured for reliability

### ✅ **Project Templates**
When you create a new project with `setup-cursor -NewProject "my-app"`, you get:

```
my-app/
├── src/                    # ← Only visible in IDE Explorer
│   └── (your code here)
├── run.ps1                # ← Hidden: Single-command project runner
├── .venv/                 # ← Hidden: Python virtual environment
├── .vscode/               # ← Hidden: IDE settings
├── main.py                # ← Hidden: Python entry point
├── package.json           # ← Hidden: JavaScript dependencies
├── pyproject.toml         # ← Hidden: Modern Python config
└── REPORT.md             # ← Hidden: Issue tracking
```

### ✅ **Global `setup-cursor` Command**
After installation, you can run `setup-cursor` from **any PowerShell terminal or Cursor session**:

```powershell
# From any directory, anywhere on your computer:
setup-cursor -Setup              # Complete environment setup
setup-cursor -NewProject "web-app"  # Create new project
setup-cursor -Doctor             # Check everything works
setup-cursor -InstallTools       # Just install UV, Bun, Git
```

## 📦 Installation Options

### 🌐 **From Any Computer (Recommended)**
**One command from any Windows PC with internet:**

```powershell
# Install globally (works from anywhere)
irm https://raw.githubusercontent.com/moarbetsy/setup-cursor/main/install-from-anywhere.ps1 | iex
```

**That's it!** You now have `setup-cursor` available globally.

### 📁 **Manual Installation**
1. Download/clone this repository
2. Run `.\install-global.ps1 -Method PowerShellProfile`
3. Restart PowerShell/Cursor

### 🛍️ **Future Distribution**
- **Winget**: `winget install YourName.SetupCursor`
- **PowerShell Gallery**: `Install-Module setup-cursor`
- **GitHub Releases**: Download ZIP, extract, run installer

## 🔄 **The Setup Process: What Actually Happens**

When you run `setup-cursor -Setup`, here's exactly what happens:

### **Step 1: Tool Installation & Updates** 🔧
- Downloads and installs **UV** (fast Python package manager)
- Downloads and installs **Bun** (fast JavaScript runtime)
- Downloads and installs **Git** (version control)
- Updates all tools to latest versions
- Refreshes your system PATH

### **Step 2: Python Environment Setup** 🐍
- Updates Python to latest version
- Creates/updates virtual environment (`.venv/`)
- Installs all dependencies from `pyproject.toml` and `requirements.txt`
- Validates everything works correctly

### **Step 3: IDE Configuration** ⚙️
- Applies optimized Cursor/VSCode settings
- Configures PowerShell 7 as default terminal
- Sets up IntelliSense for Python, JavaScript, PowerShell
- Applies file exclusions for clean workspace view
- Optimizes PowerShell extension for stability

### **Step 4: Issue Resolution** 🔧
- Fixes known PowerShell extension crashes
- Sets proper execution policies
- Applies UTF-8 encoding everywhere
- Resolves virtual environment conflicts
- Applies all fixes from `REPORT.md`

### **Step 5: Project Bootstrap** 📁
- Creates missing essential files
- Sets up proper project structure
- Initializes issue tracking (`REPORT.md`)
- Prepares everything for development

### **Step 6: Validation** ✅
- Runs comprehensive health checks
- Verifies all tools work correctly
- Confirms environment is ready for coding

**Result**: You're ready to code! Just run `setup-cursor -NewProject "my-app"` and start developing.

## 🏗️ **Project Structure Philosophy**

**"Everything I touch goes in `src/`; everything else is the machine room."**

### **What You See in IDE Explorer:**
```
my-project/
└── src/          ← Your code goes here (only visible folder)
```

### **What Actually Exists (Hidden from View):**
- `run.ps1` - Project runner and utilities
- `.venv/` - Python virtual environment
- `.vscode/` - IDE settings (exclusions, formatting)
- `node_modules/` - JavaScript dependencies
- `main.py` - Python entry point template
- `package.json` - JavaScript configuration
- `pyproject.toml` - Modern Python configuration
- `REPORT.md` - Issue tracking and troubleshooting

> **Hidden ≠ Broken**: All files remain fully functional and accessible. The IDE just doesn't show them for a cleaner, code-focused view.

## 🎛️ **Interactive Dashboard**

When you run `setup-cursor` in a project, you get this menu:

```
== SETUP PROJECT DASHBOARD ==
Project: C:\Users\You\Desktop\my-project

 [1] Run Python Entrypoint (main.py)
 [2] Run JS Entrypoint (bun run dev)
 [3] Apply Cursor/VSCode Settings
 [4] Clean Project (Reset venv/modules)
 [5] Reveal hidden project files
 [6] Run Comprehensive Setup (winget-like)
 [7] Install/Update Development Tools
 [8] Update Python Environment
 [9] Apply Known Issue Fixes
 [Q] Quit

Select an option:
```

**Option 5** reveals all hidden files if you need to access them.

## 📁 Clean Project Structure

New projects created with `-NewProject` show **only** the `src/` folder in your IDE Explorer:

```
my-awesome-project/
└── src/          ← Only visible folder in IDE Explorer
```

**Everything else exists but is excluded from IDE view:**
- `run.ps1` - Project runner and utilities
- `.venv/` - Python virtual environment
- `.vscode/` - VSCode/Cursor settings
- `.cursor/` - Cursor AI rules
- `node_modules/` - JavaScript dependencies
- `logs/` - Execution logs
- `REPORT.md` - Issue tracking
- And more...

> **Excluded ≠ Broken**: All files remain fully functional and accessible. You can still run `.\run.ps1` - the IDE just doesn't show it by default for a cleaner view!


## ⚙️ **Configuration & Customization**

### **Environment Variables**
Create a `.env` file in your project root for secrets and config:

```bash
# .env
API_KEY=your-secret-key
DEBUG=true
DATABASE_URL=sqlite:///app.db
```

Variables are automatically loaded when you run your project.

### **Project Entrypoints**
Projects auto-detect and run:

- **Python**: `main.py` (or specify with `-PythonEntrypoint ".\custom.py"`)
- **JavaScript**: `bun run dev` from `package.json` (or specify with `-JsScript "build"`)

### **IDE Settings Applied**
- PowerShell 7 as default terminal
- IntelliSense optimized for Python/JavaScript/PowerShell
- Auto-formatting on save
- File exclusions for clean workspace view
- UTF-8 encoding everywhere

## 🔍 **Troubleshooting**

### **Common Issues & Solutions**

#### **PowerShell Execution Policy Blocked**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### **Bun Installation Fails**
```powershell
# Try the correct package ID
winget install -e --id Oven-sh.Bun

# For older CPUs without AVX2 support
winget install -e --id Oven-sh.Bun.Baseline
```

#### **Need to See Hidden Project Files?**
Run your project and choose option **5** from the dashboard to reveal all files in IDE Explorer.

#### **Check Environment Health**
```powershell
setup-cursor -Doctor
```

#### **Reset Everything**
```powershell
setup-cursor -Clean  # Clean current project
setup-cursor -Setup  # Re-run complete setup
```

### **Terminal Issues in Cursor**
Enable "Legacy Terminal Tool" in Cursor settings (`Ctrl+Shift+J` → Chat/Agents → Terminal).

### **Need Help?**
- Check `REPORT.md` in your project for known issues and solutions
- All errors are logged with prevention strategies
- Run `setup-cursor -Doctor` for automated diagnostics

## 🎯 **Philosophy**

**"Everything I touch goes in `src/`; everything else is the machine room."**

### **Design Principles:**
- **Clean Explorer**: Your IDE shows only your code, not tooling
- **Zero-config**: Projects work immediately after creation
- **Stable**: Battle-tested for Windows + Cursor + PowerShell
- **Flexible**: Supports Python, JavaScript, or both in one project
- **Debuggable**: Every issue is tracked with prevention strategies

### **What Makes It Different:**
- **Modern tooling**: UV + Bun instead of pip + npm
- **Global availability**: Install from any Windows computer
- **Professional structure**: Clean separation of code and tooling
- **Issue tracking**: Built-in `REPORT.md` prevents repeating mistakes
- **One-command setup**: Winget-like experience for development environments

## 📝 **Project Contents**

Every `setup-cursor -NewProject` creates:

- **`src/`** - Your actual code (only visible in IDE)
- **`run.ps1`** - Single-command project runner
- **`main.py`** - Python entry point (auto-runs)
- **`pyproject.toml`** - Modern Python dependencies (UV)
- **`package.json`** - JavaScript dependencies (Bun)
- **`.gitignore`** - Proper Git ignore patterns
- **`REPORT.md`** - Issue tracking and solutions

**Hidden but functional:**
- `.venv/` - Python virtual environment
- `.vscode/` - IDE settings and file exclusions
- `.cursor/` - AI assistance rules
- `node_modules/` - JavaScript dependencies

## 🚀 **Ready to Code!**

After running `setup-cursor -Setup`, you have a complete development environment. Create your first project:

```powershell
setup-cursor -NewProject "my-awesome-app"
cd "my-awesome-app"
setup-cursor  # Runs your project!
```

**Welcome to professional, streamlined Windows development!** 🎉✨
