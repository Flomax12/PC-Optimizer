// ===========================================================================
//  Setup.cs - instalador de PC Optimizer
//
//  Se compila con csc.exe (incluido en .NET Framework) y lleva el ZIP de la
//  aplicacion embebido como recurso. No descarga nada de internet.
//
//  Instala en %LOCALAPPDATA%\PC-Optimizer, que no requiere ser administrador.
//  La aplicacion pide elevacion por su cuenta solo cuando se ejecuta.
// ===========================================================================
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

static class Setup
{
    const string NOMBRE = "PC Optimizer";

    static string Destino {
        get {
            return Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "PC-Optimizer");
        }
    }

    static Label  estado;
    static Button botonInstalar, botonAbrir;

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        var ventana = new Form {
            Text = NOMBRE + " - Instalador",
            ClientSize = new Size(520, 350),
            FormBorderStyle = FormBorderStyle.FixedDialog,
            MaximizeBox = false, MinimizeBox = false,
            StartPosition = FormStartPosition.CenterScreen,
            BackColor = Color.FromArgb(22, 22, 26),
            Font = new Font("Segoe UI", 9f)
        };

        var titulo = new Label {
            Text = NOMBRE,
            ForeColor = Color.FromArgb(242, 242, 245),
            Font = new Font("Segoe UI Semibold", 17f, FontStyle.Bold),
            Location = new Point(28, 24), AutoSize = true
        };

        var sub = new Label {
            Text = "Optimizador de Windows 11 con reversion completa",
            ForeColor = Color.FromArgb(154, 154, 165),
            Location = new Point(30, 58), AutoSize = true
        };

        var cuerpo = new Label {
            Text =
                "Que hace:\n" +
                "   -  Cinco niveles: Basico, Medio, Avanzado, Fortnite y Valorant\n" +
                "   -  Guarda el valor anterior de CADA cambio y permite deshacerlo\n" +
                "   -  No toca animaciones, transparencias, Defender ni Windows Update\n" +
                "   -  No toca ni elude ningun anticheat\n\n" +
                "Se instalara en:\n" +
                "   " + Destino + "\n\n" +
                "No hace falta ser administrador para instalar. La aplicacion\n" +
                "pedira permisos solo cuando la ejecutes.",
            ForeColor = Color.FromArgb(200, 200, 210),
            Location = new Point(30, 92), Size = new Size(465, 165)
        };

        estado = new Label {
            Text = "", ForeColor = Color.FromArgb(76, 194, 255),
            Location = new Point(30, 262), Size = new Size(465, 34)
        };

        botonInstalar = new Button {
            Text = "Instalar", Size = new Size(130, 34),
            Location = new Point(355, 300),
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(76, 194, 255),
            ForeColor = Color.FromArgb(8, 32, 43),
            Font = new Font("Segoe UI Semibold", 9.5f, FontStyle.Bold)
        };
        botonInstalar.FlatAppearance.BorderSize = 0;
        botonInstalar.Click += Instalar;

        botonAbrir = new Button {
            Text = "Abrir " + NOMBRE, Size = new Size(150, 34),
            Location = new Point(195, 300), Visible = false,
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(46, 46, 54),
            ForeColor = Color.FromArgb(242, 242, 245)
        };
        botonAbrir.FlatAppearance.BorderColor = Color.FromArgb(61, 61, 72);
        botonAbrir.Click += delegate {
            Process.Start(new ProcessStartInfo {
                FileName = Path.Combine(Destino, "Iniciar.bat"),
                WorkingDirectory = Destino, UseShellExecute = true
            });
            Application.Exit();
        };

        var salir = new Button {
            Text = "Salir", Size = new Size(90, 34), Location = new Point(30, 300),
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(46, 46, 54),
            ForeColor = Color.FromArgb(242, 242, 245)
        };
        salir.FlatAppearance.BorderColor = Color.FromArgb(61, 61, 72);
        salir.Click += delegate { Application.Exit(); };

        ventana.Controls.AddRange(new Control[] {
            titulo, sub, cuerpo, estado, botonInstalar, botonAbrir, salir });
        Application.Run(ventana);
    }

    static void Instalar(object s, EventArgs e)
    {
        botonInstalar.Enabled = false;
        try {
            bool actualizacion = Directory.Exists(Path.Combine(Destino, "src"));
            estado.Text = actualizacion
                ? "Actualizando (tu respaldo de cambios se conserva)..."
                : "Copiando archivos...";
            Application.DoEvents();

            int n = Extraer();

            estado.Text = "Creando accesos directos...";
            Application.DoEvents();
            CrearAccesos();

            estado.ForeColor = Color.FromArgb(125, 223, 142);
            estado.Text = n + " archivos instalados. Acceso directo en el Escritorio.\n" +
                          "Antes de aplicar nada: crea un punto de restauracion.";
            botonInstalar.Visible = false;
            botonAbrir.Visible = true;
        }
        catch (Exception ex) {
            estado.ForeColor = Color.FromArgb(255, 143, 143);
            estado.Text = "Error: " + ex.Message;
            botonInstalar.Enabled = true;
        }
    }

    // Extrae el ZIP embebido sobrescribiendo, pero sin borrar lo que no venga
    // en el paquete (por ejemplo data\backup.json del equipo).
    static int Extraer()
    {
        int n = 0;
        var asm = Assembly.GetExecutingAssembly();
        using (Stream raw = asm.GetManifestResourceStream("payload.zip")) {
            if (raw == null) throw new Exception("el paquete viene sin contenido");
            using (var zip = new ZipArchive(raw, ZipArchiveMode.Read)) {
                string padre = Directory.GetParent(Destino).FullName;
                foreach (var entrada in zip.Entries) {
                    string ruta = Path.GetFullPath(Path.Combine(padre, entrada.FullName));
                    if (!ruta.StartsWith(padre, StringComparison.OrdinalIgnoreCase))
                        throw new Exception("ruta invalida en el paquete");
                    if (string.IsNullOrEmpty(entrada.Name)) {   // es una carpeta
                        Directory.CreateDirectory(ruta);
                        continue;
                    }
                    Directory.CreateDirectory(Path.GetDirectoryName(ruta));
                    entrada.ExtractToFile(ruta, true);
                    n++;
                }
            }
        }
        return n;
    }

    static void CrearAccesos()
    {
        string lanzador = Path.Combine(Destino, "Iniciar.bat");
        string menu = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            @"Microsoft\Windows\Start Menu\Programs");
        string escritorio = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);

        var shellType = Type.GetTypeFromProgID("WScript.Shell");
        if (shellType == null) return;        // sin accesos directos, pero instalado
        object shell = Activator.CreateInstance(shellType);

        foreach (string carpeta in new[] { escritorio, menu }) {
            object lnk = shellType.InvokeMember("CreateShortcut",
                BindingFlags.InvokeMethod, null, shell,
                new object[] { Path.Combine(carpeta, NOMBRE + ".lnk") });
            var t = lnk.GetType();
            t.InvokeMember("TargetPath", BindingFlags.SetProperty, null, lnk, new object[] { lanzador });
            t.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, lnk, new object[] { Destino });
            t.InvokeMember("IconLocation", BindingFlags.SetProperty, null, lnk, new object[] { "shell32.dll,15" });
            t.InvokeMember("Description", BindingFlags.SetProperty, null, lnk,
                new object[] { "Optimizador de Windows 11 con reversion completa" });
            t.InvokeMember("Save", BindingFlags.InvokeMethod, null, lnk, null);
        }
    }
}
