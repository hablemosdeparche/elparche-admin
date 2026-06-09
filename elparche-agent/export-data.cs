using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Web.Script.Serialization;

class Program {
    static string DB, OUT_DIR;

    static void Main(string[] args) {
        DB = @"C:\Users\DIEGO\Desktop\moweb\billing-db.json";
        OUT_DIR = @"C:\Users\DIEGO\Desktop\moweb\reportes";
        Directory.CreateDirectory(OUT_DIR);

        string json = File.ReadAllText(DB, Encoding.UTF8);
        if (json.Length > 0 && json[0] == '\uFEFF') json = json.Substring(1);

        var js = new JavaScriptSerializer();
        var db = js.Deserialize<Dictionary<string, object>>(json);
        var venuesRaw = db["venues"] as ArrayList;
        if (venuesRaw == null || venuesRaw.Count == 0) {
            Console.WriteLine("No venues found"); Console.ReadLine(); return;
        }

        var venues = new List<Dictionary<string, object>>();
        foreach (var v in venuesRaw) venues.Add(v as Dictionary<string, object>);

        string timestamp = DateTime.Now.ToString("yyyy-MM-dd_HH-mm");
        string generalFile = Path.Combine(OUT_DIR, "general_" + timestamp + ".csv");
        var cityGroups = new Dictionary<string, List<Dictionary<string, object>>>();

        using (var sw = new StreamWriter(generalFile, false, Encoding.UTF8)) {
            sw.WriteLine("ID,Nombre,Categoria,Ciudad,Barrio,Plan,Precio,FechaReg,FechaIni,FechaVen,Estado,MetodoPago,Comprobante,Notas,Activo,UpdatedAt");
            foreach (var v in venues) {
                string ciudad = (Get(v, "Ciudad") ?? "").ToLower().Trim();
                if (!cityGroups.ContainsKey(ciudad)) cityGroups[ciudad] = new List<Dictionary<string, object>>();
                cityGroups[ciudad].Add(v);
                sw.WriteLine(CSVLine(v));
            }
        }
        Console.WriteLine("General: " + generalFile + " (" + venues.Count + " venues)");

        foreach (var kv in cityGroups) {
            string cityFile = Path.Combine(OUT_DIR, kv.Key + "_" + timestamp + ".csv");
            using (var sw = new StreamWriter(cityFile, false, Encoding.UTF8)) {
                sw.WriteLine("ID,Nombre,Categoria,Ciudad,Barrio,Plan,Precio,FechaReg,FechaIni,FechaVen,Estado,MetodoPago,Comprobante,Notas,Activo,UpdatedAt");
                foreach (var v in kv.Value) sw.WriteLine(CSVLine(v));
            }
            Console.WriteLine(kv.Key + ": " + cityFile + " (" + kv.Value.Count + " venues)");
        }

        Console.WriteLine("Listo! Archivos en: " + OUT_DIR);
    }

    static string Get(Dictionary<string, object> d, string k) {
        object v; return d.TryGetValue(k, out v) ? (v == null ? "" : v.ToString()) : "";
    }

    static string CSVLine(Dictionary<string, object> v) {
        return Q(Get(v,"ID")) + "," + Q(Get(v,"Nombre")) + "," + Q(Get(v,"Categoria")) + ","
            + Q(Get(v,"Ciudad")) + "," + Q(Get(v,"Barrio")) + "," + Q(Get(v,"Plan")) + ","
            + Q(Get(v,"Precio")) + "," + Q(Get(v,"FechaReg")) + "," + Q(Get(v,"FechaIni")) + ","
            + Q(Get(v,"FechaVen")) + "," + Q(Get(v,"Estado")) + "," + Q(Get(v,"MetodoPago")) + ","
            + Q(Get(v,"Comprobante")) + "," + Q(Get(v,"Notas")) + "," + Q(Get(v,"activo")) + ","
            + Q(Get(v,"updatedAt"));
    }

    static string Q(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        if (s.Contains(",") || s.Contains("\"") || s.Contains("\n") || s.Contains("\r"))
            return "\"" + s.Replace("\"", "\"\"") + "\"";
        return s;
    }
}
