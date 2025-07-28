**Pre-Workshop Installation Instructions**

These instructions will guide you through installing **Pumas 2.7.0 (pre-release)**, **Quarto** and **Visual Studio Code**, ensuring a smooth setup for the workshop.
Please read and follow **all steps** carefully prior to the session.

---

## 1. Install Pumas 2.7.0 (pre-release)

1. **Install the Julia version manager (Juliaup)**:
   - **Windows**: Install Juliaup from the [**Windows store**](https://www.microsoft.com/store/apps/9NJNWW8PVKMN).
   - **macOS**: Open the **Terminal** application and execute
     ```shell
     curl -fsSL https://install.julialang.org | sh
     ```

2. **Ensure the latest Julia release is installed**:
   - Open the **Terminal** application on your computer.
   - In the terminal, execute the following command to install the latest Julia release:
     ```shell
     juliaup add release
     ```

3. **Install the Pumas product manager**:
   - Open the **Terminal** application on your computer.
   - In the terminal, execute the following command to start a Julia REPL with a separate environment for the Pumas product manager:
     ```shell
     julia --project=@PumasProductManager
     ```
   - Run the following command in the Julia REPL to install the Pumas product manager:
     ```julia
     import Pkg; Pkg.add(url="https://github.com/PumasAI/PumasProductManager.jl")
     ```

4. **Install Pumas 2.7.0 (pre-release)**:
   - Open the **Terminal** application on your computer.
   - In the terminal, execute the following command to open the Pumas product manager:
     ```shell
     julia +PumasProductManager
     ```
   - In the Pumas product manager, type `] pumas init Pumas@2.7.0-prerelease` and press Enter.
   - This will download and install the latest pre-release version of Pumas 2.7.0.

5. **Make Pumas 2.7.0 the default Juliaup channel**:
   - Open the **Terminal** application on your computer.
   - In the terminal, execute the following command:
     ```shell
     juliaup default Pumas@2.7.0-prerelease
     ```

6. **Enter Pumas license key**:
   - Have your Pumas license key ready.
   - Open the **Terminal** application on your computer.
   - In the terminal, execute the following command:
     ```shell
     julia
     ```
   - In the Julia REPL, run the following command to launch Pumas:
     ```julia
     using Pumas
     ```
   - When asked for your license, select **enter license key** and enter your license key.
   - If successful, the license information is printed.

---

## 2. Install Quarto

1. **Download Quarto**:
   - **Windows**: [quarto-1.7.32-win.msi](https://github.com/quarto-dev/quarto-cli/releases/download/v1.7.32/quarto-1.7.32-win.msi)  
   - **macOS**: [quarto-1.7.32-macos.pkg](https://github.com/quarto-dev/quarto-cli/releases/download/v1.7.32/quarto-1.7.32-macos.pkg)

2. **Run the installer** and follow all on-screen instructions to complete the Quarto installation.

---

## 3. Install Visual Studio Code (VS Code)

1. **Download VS Code**:
   - **Windows**: [VSCodeSetup-x64-1.102.2.exe](https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user)
   - **macOS**: [VSCode-darwin-universal.zip](https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal)

2. **Run the installer** and follow all on-screen instructions to complete the VS Code installation.

---

## 4. Install Required Extensions in VS Code

1. **Open VS Code**.

2. **Access the Extensions Marketplace**:
   - Look for the **Extensions** icon on the left-hand sidebar.  
   - Click to open the Marketplace.

3. **Install the Julia extension**:
   - Search for **"julialang.language-julia"** in Extensions Marketplace.
   - Click on the **“Install”** button next to the Julia extension.

4. **Install the Quarto extension**:
   - Search for **"quarto.quarto"** in the Extensions Marketplace.
   - Click on the **“Install”** button next to the Quarto extension.

---

## 5. Configure VS Code for Pumas 2.7.0 (pre-release)

1. **Open VS Code**.

2. **Open the VS Code settings**:
   - Click on the gear icon in the lower left corner of the VS Code window and select **"Settings"** from the menu.
     (or press `Ctrl+,` on Windows or `Cmd+,` on macOS).

3. **Configure the path to the Pumas executable**:
   - In the search bar at the top of the Settings panel, type **"julia executable path"**.
   - Select the **"Julia: Executable Path"** setting.
   - **Windows**: Set it to `julia.exe +Pumas@2.7.0-prerelease`.
   - **macOS**: Set it to `julia +Pumas@2.7.0-prerelease`.

4. **Configure the path to tbe Pumas environment**:
   - In the search bar at the top of the Settings panel, type **"julia environment path"**.
   - Select the **"Julia: Environment Path"** setting and press **Edit in settings.json**.
   - Add the following line to the `settings.json` file:
     ```json
     "julia.environmentPath": "~/.julia/environments/Pumas@2.7.0-prerelease",
     ```

---

## 6. Verify Your Setup

1. **Obtain the provided `check_quarto.qmd` file** and place it somewhere on your computer.
2. **Open the `check_quarto.qmd` file in VS Code**.
3. **Check Quarto settings**:
   - Click on the gear icon in the lower left corner of the VS Code window and select **"Command Palette..."** from the menu.
     (or press `Ctrl+Shift+P` on Windows or `Cmd+Shift+P` on macOS).
   - Type **“quarto render”** in the Command Palette and select **"Quarto: Render Document**.
   - If the process completes without error and an HTML file is produced, your Quarto setup for Pumas is correct.
4. **Check terminal settings**:
   - Click on the gear icon in the lower left corner of the VS Code window and select **"Command Palette..."** from the menu.
     (or press `Ctrl+Shift+P` on Windows or `Cmd+Shift+P` on macOS).
   - Type **"julia start repl”** in the Command Palette and select **"Julia: Start REPL**.
   - Execute the following commands:
     ```julia
     using Pumas
     ```
   - If your license information is printed without errors, your terminal setup for Pumas is correct. 

---

## Additional Tips

- **Restart VS Code** if you do not see the Quarto extension commands.  
- **Keep your internet connection stable** while installing and updating tools.  
- Ensure you have sufficient permissions to install software on your machine. On some systems, you may need administrative or root privileges.  

---

**If you encounter any issues,** please capture screenshots or error messages and reach out to the workshop support team for assistance. We look forward to working with you during the session!
