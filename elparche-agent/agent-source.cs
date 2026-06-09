using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using System.Text;

public class ElParcheAgentApp : Form
{
    private NotifyIcon trayIcon;
    private ContextMenuStrip trayMenu;
    private System.Windows.Forms.Timer dailyTimer;
    private string logPath, scriptPath, baseDir, statusFile;
    private int runCount = 0;

    public ElParcheAgentApp()
    {
        baseDir = Path.GetDirectoryName(Application.ExecutablePath);
        logPath = Path.Combine(baseDir, "elparche-agent.log");
        scriptPath = Path.Combine(baseDir, "elparche-core.ps1");
        statusFile = Path.Combine(baseDir, "last-run.json");
        InitIcon();
        InitTimer();
    }

    private void InitIcon()
    {
        trayIcon = new NotifyIcon();
        trayIcon.Text = "El Parche Agent";
        trayIcon.Visible = true;
        string ico = Path.Combine(baseDir, "elparche.ico");
        trayIcon.Icon = File.Exists(ico) ? new Icon(ico) : SystemIcons.Application;
        trayMenu = new ContextMenuStrip();
        trayMenu.Items.Add("Ejecutar ahora", null, (s, e) => RunCycle());
        trayMenu.Items.Add("Ver ultimo reporte", null, (s, e) => ShowReport());
        trayMenu.Items.Add("Abrir log", null, (s, e) => OpenLog());
        trayMenu.Items.Add(new ToolStripSeparator());
        trayMenu.Items.Add("Salir", null, (s, e) => ExitApp());
        trayIcon.ContextMenuStrip = trayMenu;
        trayIcon.ShowBalloonTip(3000, "El Parche Agent", "Iniciado. Ciclo diario activo.", ToolTipIcon.Info);
    }

    private void InitTimer()
    {
        dailyTimer = new System.Windows.Forms.Timer();
        dailyTimer.Interval = 60000;
        dailyTimer.Tick += (s, e) =>
        {
            dailyTimer.Interval = 86400000;
            RunCycle();
        };
        dailyTimer.Start();
        RunCycle();
    }

    private void RunCycle()
    {
        try
        {
            runCount++;
            Log("=== RUN #" + runCount + " ===");
            trayIcon.Text = "El Parche Agent (corriendo...)";
            if (!File.Exists(scriptPath))
            {
                Log("ERROR: Script no encontrado: " + scriptPath);
                trayIcon.ShowBalloonTip(5000, "Error", "Script no encontrado: elparche-core.ps1", ToolTipIcon.Error);
                trayIcon.Text = "El Parche Agent (error)";
                return;
            }
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + scriptPath + "\"",
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };
            using (Process proc = Process.Start(psi))
            {
                string output = proc.StandardOutput.ReadToEnd();
                string error = proc.StandardError.ReadToEnd();
                proc.WaitForExit(120000);
                Log(output);
                if (!string.IsNullOrEmpty(error)) Log("STDERR: " + error);
                string[] lines = output.Trim().Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries);
                if (lines.Length > 0) File.WriteAllText(statusFile, lines[lines.Length - 1]);
                trayIcon.Text = "El Parche Agent";
                trayIcon.ShowBalloonTip(5000, "El Parche Agent", "Ciclo completado.", ToolTipIcon.Info);
            }
        }
        catch (Exception ex)
        {
            Log("FATAL: " + ex.ToString());
            trayIcon.ShowBalloonTip(5000, "El Parche Agent", "Error: " + ex.Message, ToolTipIcon.Error);
        }
    }

    private void ShowReport()
    {
        try
        {
            if (File.Exists(statusFile))
                MessageBox.Show(File.ReadAllText(statusFile), "Ultimo Reporte", MessageBoxButtons.OK, MessageBoxIcon.Information);
            else
                MessageBox.Show("No hay reporte aun.", "El Parche Agent", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex) { MessageBox.Show("Error: " + ex.Message, "Error"); }
    }

    private void OpenLog()
    {
        if (File.Exists(logPath)) Process.Start("notepad.exe", logPath);
        else MessageBox.Show("Log no encontrado.", "El Parche Agent");
    }

    private void ExitApp() { trayIcon.Visible = false; Application.Exit(); }

    private void Log(string msg)
    {
        string line = "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "] " + msg;
        File.AppendAllText(logPath, line + Environment.NewLine);
    }

    protected override void OnLoad(EventArgs e) { Visible = false; ShowInTaskbar = false; base.OnLoad(e); }

    protected override void Dispose(bool disposing)
    {
        if (disposing && trayIcon != null) trayIcon.Dispose();
        base.Dispose(disposing);
    }

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (var app = new ElParcheAgentApp()) { Application.Run(app); }
    }
}
