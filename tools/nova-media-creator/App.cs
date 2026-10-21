// NOVA Media Creation Tool. The raw media-writing helper is the unchanged,
// hash-pinned Fedora Media Writer 5.3.2 helper distributed under GPLv2.
// This frontend is C# 5 / .NET Framework 4.8 for a native Windows executable.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Management;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Nova.MediaCreator
{
    internal static class Release
    {
        public const long IsoBytes = 5348950016L;
        public const string IsoSha256 = "d1b7322bae282c4588430e0f67657a73f0ccc2ef275770e35c2b759cd0019f7a";
        public const string IsoName = "NOVA-OS-0.2-Preview-x86_64.iso";
        public const string VendorZipSha256 = "1043a01b5bfc4b0a79b4f431696eeaeb18c605f38579009877aada3a836904da";
        public const string HelperSha256 = "bcb7c9f9d57ad58bbc8433e475af8fec13e47c5b236dc4bab1c61ceeb7cf6303";
        public const string VendorVersion = "5.3.2";
        public const long MinimumUsbBytes = 8L * 1024L * 1024L * 1024L;
    }

    internal sealed class UsbDisk
    {
        public int Number;
        public string Model;
        public string Serial;
        public string UniqueId;
        public long Size;
        public string Letters;
        public string Fingerprint
        {
            get { return Number + "|" + UniqueId + "|" + Serial + "|" + Model + "|" + Size; }
        }
        public string DisplayName
        {
            get { return (String.IsNullOrWhiteSpace(Model) ? "USB drive" : Model.Trim()) + "  ·  " + FormatSize(Size) + (String.IsNullOrWhiteSpace(Letters) ? "" : "  ·  " + Letters); }
        }
        private static string FormatSize(long bytes) { return (bytes / 1073741824.0).ToString("0.0") + " GB"; }
    }

    internal static class DiskInventory
    {
        private static object Read(ManagementBaseObject item, string name)
        {
            try { return item[name]; } catch { return null; }
        }
        private static bool RequiredBool(ManagementBaseObject item, string name)
        {
            object value = Read(item, name);
            if (value == null) throw new InvalidOperationException("Windows nu a raportat starea de siguranță „" + name + "”. Scrierea rămâne dezactivată.");
            return Convert.ToBoolean(value);
        }
        private static string Text(object value) { return value == null ? "" : Convert.ToString(value).Trim(); }

        public static List<UsbDisk> ListEligible()
        {
#if PREVIEW
            return new List<UsbDisk> { new UsbDisk { Number = 17, Model = "NOVA Preview USB (simulat)", Serial = "PREVIEW-ONLY", UniqueId = "PREVIEW-ONLY", Size = 16L * 1073741824L, Letters = "fără dispozitiv real" } };
#else
            List<UsbDisk> result = new List<UsbDisk>();
            using (ManagementObjectSearcher search = new ManagementObjectSearcher("root\\Microsoft\\Windows\\Storage", "SELECT Number, BusType, FriendlyName, Model, SerialNumber, UniqueId, Size, IsBoot, IsSystem, IsReadOnly, IsOffline FROM MSFT_Disk"))
            using (ManagementObjectCollection disks = search.Get())
            {
                foreach (ManagementObject item in disks)
                {
                    object n = Read(item, "Number"), bus = Read(item, "BusType"), size = Read(item, "Size");
                    if (n == null || bus == null || size == null) continue;
                    int number = Convert.ToInt32(n);
                    if (number <= 0 || Convert.ToUInt16(bus) != 7) continue;
                    string unique = Text(Read(item, "UniqueId"));
                    string serial = Text(Read(item, "SerialNumber"));
                    string model = Text(Read(item, "FriendlyName"));
                    if (String.IsNullOrWhiteSpace(model)) model = Text(Read(item, "Model"));
                    long bytes = Convert.ToInt64(size);
                    if (bytes < Release.MinimumUsbBytes || (String.IsNullOrWhiteSpace(unique) && String.IsNullOrWhiteSpace(serial))) continue;
                    bool boot = RequiredBool(item, "IsBoot"), system = RequiredBool(item, "IsSystem");
                    bool readOnly = RequiredBool(item, "IsReadOnly"), offline = RequiredBool(item, "IsOffline");
                    if (boot || system || readOnly || offline) continue;
                    string letters = GetLetters(number);
                    // A mounted volume identity is needed to refuse a target which
                    // also contains the selected ISO or this running application.
                    if (String.IsNullOrWhiteSpace(letters)) continue;
                    result.Add(new UsbDisk { Number = number, Model = model, Serial = serial, UniqueId = unique, Size = bytes,
                        Letters = letters });
                }
            }
            return result;
#endif
        }

        private static string GetLetters(int number)
        {
            List<string> letters = new List<string>();
            try
            {
                using (ManagementObjectSearcher drives = new ManagementObjectSearcher("root\\CIMV2", "SELECT Index, DeviceID FROM Win32_DiskDrive"))
                using (ManagementObjectCollection found = drives.Get())
                foreach (ManagementObject drive in found)
                {
                    if (Convert.ToInt32(drive["Index"]) != number) continue;
                    string path = Convert.ToString(drive["DeviceID"]).Replace("'", "\\'");
                    string query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='" + path + "'} WHERE AssocClass=Win32_DiskDriveToDiskPartition";
                    using (ManagementObjectSearcher partitions = new ManagementObjectSearcher("root\\CIMV2", query))
                    using (ManagementObjectCollection parts = partitions.Get())
                    foreach (ManagementObject part in parts)
                    {
                        string partPath = Convert.ToString(part.Path.RelativePath).Replace("'", "\\'");
                        string logicalQuery = "ASSOCIATORS OF {" + partPath + "} WHERE AssocClass=Win32_LogicalDiskToPartition";
                        using (ManagementObjectSearcher logicals = new ManagementObjectSearcher("root\\CIMV2", logicalQuery))
                        using (ManagementObjectCollection volumes = logicals.Get())
                        foreach (ManagementObject volume in volumes)
                            letters.Add(Convert.ToString(volume["DeviceID"]));
                    }
                }
            }
            catch { return ""; }
            return String.Join(", ", letters.Distinct().ToArray());
        }

        public static UsbDisk Revalidate(UsbDisk chosen)
        {
#if PREVIEW
            if (chosen == null || chosen.Serial != "PREVIEW-ONLY") throw new InvalidOperationException("Dispozitivul de previzualizare nu mai este valid.");
            return chosen;
#else
            if (chosen == null) throw new InvalidOperationException("Alege un stick USB.");
            UsbDisk current = ListEligible().FirstOrDefault(d => d.Number == chosen.Number && d.Fingerprint == chosen.Fingerprint);
            if (current == null) throw new InvalidOperationException("Stickul s-a schimbat sau nu mai trece verificările de siguranță. Actualizează lista și alege din nou.");
            return current;
#endif
        }

        public static void RejectSourceOnTarget(UsbDisk disk, string isoPath)
        {
#if !PREVIEW
            if (!Regex.IsMatch(Path.GetPathRoot(Path.GetFullPath(isoPath)), "^[A-Za-z]:\\\\$"))
                throw new InvalidOperationException("Alege un ISO de pe un disc local Windows, pentru ca aplicația să poată exclude în siguranță discul-sursă.");
            string letters = "," + (disk.Letters ?? "").Replace(" ", "").ToUpperInvariant() + ",";
            string isoRoot = Path.GetPathRoot(Path.GetFullPath(isoPath)).TrimEnd('\\').ToUpperInvariant();
            string appRoot = Path.GetPathRoot(Path.GetFullPath(Application.ExecutablePath)).TrimEnd('\\').ToUpperInvariant();
            if (letters.Contains("," + isoRoot + ",") || letters.Contains("," + appRoot + ","))
                throw new InvalidOperationException("ISO-ul sau aplicația se află pe stickul ales. Alege un alt stick și păstrează fișierele de instalare pe discul laptopului.");
#endif
        }
    }

    internal sealed class WriteProgress
    {
        public string Phase;
        public long Bytes;
        public long Total;
        public string Detail;
    }

    internal static class WriteOutcome
    {
        internal static string CancelStatus(int stage)
        {
            return stage >= 2 ? "Scriere anulată · stickul poate conține date incomplete" : stage == 1 ?
                "Componenta USB s-a oprit înainte de confirmarea scrierii" : "Pregătire anulată · scrierea nu a început";
        }
        internal static string CancelDetail(int stage)
        {
            return stage >= 2 ? "Nu folosi stickul până când nu îl creezi din nou." : stage == 1 ?
                "Verifică stickul înainte să îl folosești, apoi reia pregătirea." : "Stickul nu a fost modificat.";
        }
        internal static string FailureDetail(int stage)
        {
            return stage >= 2 ? "Scrierea a început; stickul poate conține date incomplete." : stage == 1 ?
                "Componenta USB a fost pornită; verifică stickul înainte să îl folosești." :
                "Scrierea pe USB nu a început; stickul nu a fost modificat.";
        }
    }

    internal static class MediaWriter
    {
        public static async Task<bool> VerifyIsoAsync(string path, Action<long> progress, CancellationToken token)
        {
            return await Task.Run(delegate
            {
                if (String.IsNullOrWhiteSpace(path) || !File.Exists(path)) throw new FileNotFoundException("Alege imaginea NOVA ISO.");
                FileInfo info = new FileInfo(path);
                if (info.Length != Release.IsoBytes) throw new InvalidDataException("Dimensiunea ISO-ului nu corespunde imaginii NOVA 0.2 Preview.");
                string digest;
                using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 8 * 1024 * 1024, FileOptions.SequentialScan))
            using (SHA256 sha = SHA256.Create())
                {
                    byte[] buffer = new byte[8 * 1024 * 1024]; int read; long total = 0;
                    while ((read = stream.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        token.ThrowIfCancellationRequested(); sha.TransformBlock(buffer, 0, read, buffer, 0); total += read;
                        if (progress != null) progress(total);
                    }
                    sha.TransformFinalBlock(new byte[0], 0, 0); digest = BitConverter.ToString(sha.Hash).Replace("-", "").ToLowerInvariant();
                }
                if (!String.Equals(digest, Release.IsoSha256, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("SHA-256 nu corespunde NOVA OS 0.2 (" + digest + "). ISO-ul nu va fi scris pe stick.");
                return true;
            }, token).ConfigureAwait(false);
        }

        public static async Task WriteAsync(string isoPath, UsbDisk chosen, Action<WriteProgress> progress, CancellationToken token)
        {
#if PREVIEW
            await Task.Run(async delegate
            {
                for (int i = 0; i <= 10; i++) { token.ThrowIfCancellationRequested(); if (progress != null) progress(new WriteProgress { Phase = "Scriere simulată", Bytes = i, Total = 10, Detail = "Previzualizare sigură · nu este accesat niciun dispozitiv" }); await Task.Delay(160, token).ConfigureAwait(false); }
                if (progress != null) progress(new WriteProgress { Phase = "Verificare simulată", Bytes = 10, Total = 10, Detail = "Niciun stick nu a fost modificat" });
            }, token).ConfigureAwait(false);
#else
            await Task.Run(delegate
            {
                VerifyIsoAsync(isoPath, null, token).GetAwaiter().GetResult();
                UsbDisk current = DiskInventory.Revalidate(chosen);
                DiskInventory.RejectSourceOnTarget(current, isoPath);
                string helper = VendorPackage.GetVerifiedHelper();
                // A final inventory check sits directly before process creation.
                current = DiskInventory.Revalidate(current);
                DiskInventory.RejectSourceOnTarget(current, isoPath);
                ProcessStartInfo info = new ProcessStartInfo();
                info.FileName = helper;
                info.Arguments = BuildHelperArguments(isoPath, current.Number);
                info.WorkingDirectory = Path.GetDirectoryName(helper);
                info.UseShellExecute = false; info.CreateNoWindow = true;
                info.RedirectStandardOutput = true; info.RedirectStandardError = true;
                using (Process process = new Process())
                {
                    process.StartInfo = info;
                    bool wrote = false, checkedMedia = false, done = false, cancelled = false;
                    object gate = new object();
                    StringBuilder diagnostics = new StringBuilder();
                    process.OutputDataReceived += delegate(object s, DataReceivedEventArgs e)
                    {
                        if (e.Data == null) return;
                        string line = e.Data.Trim();
                        lock (gate)
                        {
                            if (line == "WRITE") { wrote = true; checkedMedia = false; if (progress != null) progress(new WriteProgress { Phase = "Scriere", Bytes = 0, Total = Release.IsoBytes }); }
                            else if (line == "CHECK") { checkedMedia = true; if (progress != null) progress(new WriteProgress { Phase = "Verificare", Bytes = 0, Total = Release.IsoBytes }); }
                            else if (line == "DONE") { done = true; if (progress != null) progress(new WriteProgress { Phase = "Verificare", Bytes = Release.IsoBytes, Total = Release.IsoBytes, Detail = "Verificarea imaginii s-a încheiat" }); }
                            else { long value; if (Int64.TryParse(line, out value) && value >= 0 && value <= Release.IsoBytes && progress != null) progress(new WriteProgress { Phase = checkedMedia ? "Verificare" : "Scriere", Bytes = value, Total = Release.IsoBytes }); }
                        }
                    };
                    process.ErrorDataReceived += delegate(object s, DataReceivedEventArgs e)
                    {
                        if (String.IsNullOrWhiteSpace(e.Data) || e.Data.Trim() == "OK") return;
                        lock (diagnostics) { if (diagnostics.Length < 3000) diagnostics.AppendLine(e.Data); }
                    };
                    token.ThrowIfCancellationRequested();
                    if (progress != null) progress(new WriteProgress { Phase = "Pornire componentă USB" });
                    if (!process.Start()) throw new InvalidOperationException("Nu am putut porni componenta de scriere.");
                    using (CancellationTokenRegistration registration = token.Register(delegate { try { if (!process.HasExited) { cancelled = true; process.Kill(); } } catch { cancelled = true; } }))
                    {
                        process.BeginOutputReadLine(); process.BeginErrorReadLine();
                        process.WaitForExit(); process.WaitForExit(); token.ThrowIfCancellationRequested();
                    }
                    if (cancelled) throw new OperationCanceledException("Scriere anulată. Stickul poate conține date incomplete.");
                    if (process.ExitCode != 0 || !wrote || !checkedMedia || !done)
                    {
                        string reason; lock (diagnostics) reason = diagnostics.ToString().Trim();
                        if (reason.Length > 700) reason = reason.Substring(0, 700) + "…";
                        throw new InvalidOperationException("Scrierea sau verificarea a eșuat (cod " + process.ExitCode + "). " + reason);
                    }
                }
            }, token).ConfigureAwait(false);
#endif
        }

        private static string Quote(string value)
        {
            StringBuilder b = new StringBuilder("\""); int slashes = 0;
            foreach (char c in value)
            {
                if (c == '\\') { slashes++; continue; }
                if (c == '"') { b.Append('\\', slashes * 2 + 1); b.Append('"'); slashes = 0; continue; }
                b.Append('\\', slashes); slashes = 0; b.Append(c);
            }
            b.Append('\\', slashes * 2); b.Append('"'); return b.ToString();
        }

        internal static string BuildHelperArguments(string isoPath, int diskNumber)
        {
            return "write " + Quote(isoPath) + " " + diskNumber.ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
    }

    internal static class VendorPackage
    {
        private const string Resource = "NOVA.Media.VendorZip";
        public static string GetVerifiedHelper()
        {
#if PREVIEW
            throw new InvalidOperationException("Previzualizarea nu include și nu poate porni componenta de scriere.");
#else
            string programData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            string nova = Path.Combine(programData, "NOVA");
            EnsureProtectedDirectory(nova);
            string app = Path.Combine(nova, "MediaCreationTool"); EnsureProtectedDirectory(app);
            string folder = Path.Combine(app, "Vendor-" + Release.VendorVersion); EnsureProtectedDirectory(folder);
            string helper = Path.Combine(folder, "helper.exe");
            if (!File.Exists(helper)) ExtractVerified(folder);
            VerifyPackageTree(folder);
            VerifyHelper(helper);
            return helper;
#endif
        }

        private static void EnsureProtectedDirectory(string path)
        {
            DirectoryInfo existing = new DirectoryInfo(path);
            if (existing.Exists)
            {
                if ((existing.Attributes & FileAttributes.ReparsePoint) != 0) throw new InvalidOperationException("Cache-ul media este un punct de legătură neașteptat. Scrierea a fost oprită.");
                VerifyAcl(existing, true);
                return;
            }
            DirectorySecurity security = new DirectorySecurity();
            security.SetAccessRuleProtection(true, false);
            SecurityIdentifier admins = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
            SecurityIdentifier system = new SecurityIdentifier(WellKnownSidType.LocalSystemSid, null);
            SecurityIdentifier users = new SecurityIdentifier(WellKnownSidType.BuiltinUsersSid, null);
            security.SetOwner(admins);
            security.AddAccessRule(new FileSystemAccessRule(admins, FileSystemRights.FullControl, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            security.AddAccessRule(new FileSystemAccessRule(system, FileSystemRights.FullControl, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            security.AddAccessRule(new FileSystemAccessRule(users, FileSystemRights.ReadAndExecute, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            try { Directory.CreateDirectory(path, security); }
            catch (IOException) { }
            existing = new DirectoryInfo(path);
            if (!existing.Exists || (existing.Attributes & FileAttributes.ReparsePoint) != 0) throw new InvalidOperationException("Nu am putut crea un cache protejat pentru componenta USB.");
            VerifyAcl(existing, true);
        }

        private static void VerifyAcl(DirectoryInfo directory, bool requireProtected)
        {
            DirectorySecurity acl = directory.GetAccessControl(AccessControlSections.Access | AccessControlSections.Owner);
            if (requireProtected && !acl.AreAccessRulesProtected) throw new InvalidOperationException("Cache-ul USB are permisiuni moștenite neașteptate.");
            SecurityIdentifier owner = (SecurityIdentifier)acl.GetOwner(typeof(SecurityIdentifier));
            SecurityIdentifier admins = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
            SecurityIdentifier system = new SecurityIdentifier(WellKnownSidType.LocalSystemSid, null);
            if (!owner.Equals(admins) && !owner.Equals(system)) throw new InvalidOperationException("Proprietarul cache-ului USB nu este de încredere.");
            AuthorizationRuleCollection rules = acl.GetAccessRules(true, false, typeof(SecurityIdentifier));
            VerifyNoUntrustedWrite(rules);
        }

        private static void VerifyNoUntrustedWrite(AuthorizationRuleCollection rules)
        {
            SecurityIdentifier admins = new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null);
            SecurityIdentifier system = new SecurityIdentifier(WellKnownSidType.LocalSystemSid, null);
            foreach (FileSystemAccessRule rule in rules)
            {
                SecurityIdentifier sid = (SecurityIdentifier)rule.IdentityReference;
                if (rule.AccessControlType == AccessControlType.Allow && !sid.Equals(admins) && !sid.Equals(system) && HasWriteAccess(rule.FileSystemRights))
                    throw new InvalidOperationException("Cache-ul USB poate fi modificat de un cont neprivilegiat. Scrierea a fost oprită.");
            }
        }

        internal static bool HasWriteAccess(FileSystemRights rights)
        {
            // Modify includes read and execute bits. Detecting it with a simple
            // bit overlap incorrectly classified Users:ReadAndExecute as write.
            const FileSystemRights write = FileSystemRights.WriteData | FileSystemRights.AppendData |
                FileSystemRights.WriteExtendedAttributes | FileSystemRights.WriteAttributes |
                FileSystemRights.DeleteSubdirectoriesAndFiles | FileSystemRights.Delete |
                FileSystemRights.ChangePermissions | FileSystemRights.TakeOwnership |
                FileSystemRights.CreateDirectories | FileSystemRights.CreateFiles;
            const int GenericWrite = 0x40000000;
            const int GenericAll = 0x10000000;
            int mask = (int)rights;
            return (rights & write) != 0 || (mask & (GenericWrite | GenericAll)) != 0;
        }

        private static void ExtractVerified(string directory)
        {
            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource))
            {
                if (input == null) throw new InvalidOperationException("Arhiva oficială a componentei de scriere lipsește.");
                using (SHA256 sha = SHA256.Create())
                {
                    byte[] digest = sha.ComputeHash(input);
                    if (BitConverter.ToString(digest).Replace("-", "").ToLowerInvariant() != Release.VendorZipSha256) throw new InvalidDataException("Arhiva Fedora Media Writer nu a trecut verificarea SHA-256.");
                }
            }
            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource))
            using (ZipArchive zip = new ZipArchive(input, ZipArchiveMode.Read, false))
            {
                foreach (ZipArchiveEntry entry in zip.Entries)
                {
                    string relative = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                    if (Path.IsPathRooted(relative) || relative.Contains(":") || relative.Split(Path.DirectorySeparatorChar).Any(p => p == ".."))
                        throw new InvalidDataException("Arhiva componentei USB conține o cale invalidă.");
                    string target = Path.GetFullPath(Path.Combine(directory, relative));
                    string root = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
                    if (!target.StartsWith(root, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Arhiva componentei USB iese din cache.");
                    if (String.IsNullOrEmpty(entry.Name)) { Directory.CreateDirectory(target); continue; }
                    string parent = Path.GetDirectoryName(target); Directory.CreateDirectory(parent);
                    using (Stream source = entry.Open())
                    using (FileStream dest = new FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None)) source.CopyTo(dest);
                }
            }
            VerifyPackageTree(directory);
        }

        private static void VerifyPackageTree(string directory)
        {
            Dictionary<string, string> expected = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource))
            using (SHA256 sha = SHA256.Create())
            {
                if (input == null || BitConverter.ToString(sha.ComputeHash(input)).Replace("-", "").ToLowerInvariant() != Release.VendorZipSha256)
                    throw new InvalidDataException("Arhiva oficială Fedora nu a trecut verificarea SHA-256.");
            }
            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource))
            using (ZipArchive zip = new ZipArchive(input, ZipArchiveMode.Read, false))
            using (SHA256 sha = SHA256.Create())
            {
                foreach (ZipArchiveEntry entry in zip.Entries)
                {
                    if (String.IsNullOrEmpty(entry.Name)) continue;
                    string relative = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                    using (Stream content = entry.Open())
                    {
                        string digest = BitConverter.ToString(sha.ComputeHash(content)).Replace("-", "").ToLowerInvariant();
                        if (expected.ContainsKey(relative)) throw new InvalidDataException("Arhiva Fedora conține nume de fișier duplicate.");
                        expected.Add(relative, digest);
                    }
                }
            }
            DirectoryInfo root = new DirectoryInfo(directory);
            foreach (DirectoryInfo child in root.GetDirectories("*", SearchOption.AllDirectories))
            {
                if ((child.Attributes & FileAttributes.ReparsePoint) != 0) throw new InvalidOperationException("Cache-ul Fedora conține un director de legătură. Scrierea a fost oprită.");
                VerifyAcl(child, false);
            }
            HashSet<string> found = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            using (SHA256 sha = SHA256.Create())
            foreach (FileInfo file in root.GetFiles("*", SearchOption.AllDirectories))
            {
                if ((file.Attributes & FileAttributes.ReparsePoint) != 0) throw new InvalidOperationException("Cache-ul Fedora conține un fișier de legătură. Scrierea a fost oprită.");
                string relative = file.FullName.Substring(root.FullName.TrimEnd(Path.DirectorySeparatorChar).Length + 1);
                string expectedHash;
                if (!expected.TryGetValue(relative, out expectedHash)) throw new InvalidDataException("Cache-ul Fedora conține un fișier suplimentar neașteptat.");
                FileSecurity acl = file.GetAccessControl(AccessControlSections.Access);
                VerifyNoUntrustedWrite(acl.GetAccessRules(true, true, typeof(SecurityIdentifier)));
                using (FileStream content = file.OpenRead())
                {
                    string actual = BitConverter.ToString(sha.ComputeHash(content)).Replace("-", "").ToLowerInvariant();
                    if (actual != expectedHash) throw new InvalidDataException("Un fișier Fedora din cache nu corespunde arhivei oficiale: " + relative);
                }
                found.Add(relative);
            }
            if (found.Count != expected.Count) throw new InvalidDataException("Cache-ul Fedora este incomplet. Componenta de scriere nu va porni.");
        }

        private static void VerifyHelper(string path)
        {
            if (!File.Exists(path)) throw new FileNotFoundException("Componenta Fedora de scriere lipsește din pachet.");
            using (FileStream stream = File.OpenRead(path))
            using (SHA256 sha = SHA256.Create())
                if (BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant() != Release.HelperSha256)
                    throw new InvalidDataException("Componenta Fedora de scriere nu a trecut verificarea SHA-256.");
        }
    }

    internal sealed class NovaForm : Form
    {
        private readonly Color bg = ColorTranslator.FromHtml("#0B0D14"), surface = ColorTranslator.FromHtml("#151923"), blue = ColorTranslator.FromHtml("#57C7FF"), violet = ColorTranslator.FromHtml("#9775FF"), mainText = ColorTranslator.FromHtml("#F3F5FA"), muted = ColorTranslator.FromHtml("#A5AEC2");
        private TextBox isoBox; private Label isoState, status, detail, step1, step2, step3; private Panel progressTrack, progressFill; private ComboBox drives; private Button verifyButton, writeButton, refreshButton, browseButton, cancelButton; private CancellationTokenSource active; private bool verified; private string isoPath = ""; private readonly List<UsbDisk> disks = new List<UsbDisk>(); private int Percent { get; set; }

        public NovaForm()
        {
            Text = "NOVA Media Creation Tool"; MinimumSize = new Size(760, 660); Size = new Size(900, 730); StartPosition = FormStartPosition.CenterScreen; BackColor = bg; ForeColor = mainText; Font = new Font("Segoe UI", 10F); DoubleBuffered = true;
            Build(); Shown += async delegate { await RefreshDrives(); AutoFindIso(); };
            FormClosing += delegate { if (active != null) active.Cancel(); };
        }

        private Label LabelText(string text, float size, bool bold, Color color)
        {
            return new Label { Text = text, AutoSize = true, ForeColor = color, Font = new Font("Segoe UI", size, bold ? FontStyle.Bold : FontStyle.Regular), BackColor = Color.Transparent, Margin = new Padding(0) };
        }
        private Panel Card(int height)
        {
            Panel card = new Panel { Height = height, Dock = DockStyle.Top, BackColor = surface, Padding = new Padding(22), Margin = new Padding(0) };
            card.Paint += delegate(object sender, PaintEventArgs e) { using (Pen p = new Pen(Color.FromArgb(40, blue), 1)) e.Graphics.DrawRectangle(p, 0, 0, card.Width - 1, card.Height - 1); };
            return card;
        }
        private Button MakeButton(string text, bool primary)
        {
            Button button = new Button { Text = text, Height = 42, AutoSize = true, FlatStyle = FlatStyle.Flat, BackColor = primary ? blue : Color.FromArgb(36, 42, 57), ForeColor = primary ? bg : mainText, Font = new Font("Segoe UI", 9.5F, FontStyle.Bold), Padding = new Padding(16, 0, 16, 0), Cursor = Cursors.Hand, Margin = new Padding(8, 0, 0, 0) };
            button.FlatAppearance.BorderSize = 0; button.FlatAppearance.MouseOverBackColor = primary ? ColorTranslator.FromHtml("#7BD4FF") : Color.FromArgb(51, 58, 76); return button;
        }
        private void Build()
        {
            Panel header = new Panel { Dock = DockStyle.Top, Height = 126, Padding = new Padding(28, 21, 28, 12) };
            header.Paint += delegate(object sender, PaintEventArgs e)
            {
                using (LinearGradientBrush brush = new LinearGradientBrush(header.ClientRectangle, ColorTranslator.FromHtml("#11192A"), bg, 0F)) e.Graphics.FillRectangle(brush, header.ClientRectangle);
                using (Pen pen = new Pen(Color.FromArgb(70, violet), 1)) e.Graphics.DrawLine(pen, 0, header.Height - 1, header.Width, header.Height - 1);
                Point[] star = new Point[] { new Point(43, 19), new Point(53, 46), new Point(82, 55), new Point(53, 64), new Point(43, 91), new Point(34, 64), new Point(5, 55), new Point(34, 46) };
                using (SolidBrush b = new SolidBrush(blue)) e.Graphics.FillPolygon(b, star);
                using (Pen p = new Pen(violet, 2)) e.Graphics.DrawArc(p, 8, 20, 75, 75, 210, 260);
            };
            Label title = LabelText("NOVA", 24F, true, mainText); title.Location = new Point(110, 27);
            Label subtitle = LabelText("MEDIA CREATION TOOL", 9F, true, blue); subtitle.Location = new Point(112, 77);
#if PREVIEW
            subtitle.Text = "PREVIEW QA  ·  SCRIEREA ESTE DEZACTIVATĂ";
#endif
            Label tag = LabelText("0.2 PREVIEW  ·  WINDOWS", 9F, false, muted); tag.Anchor = AnchorStyles.Top | AnchorStyles.Right; tag.Location = new Point(Width - 250, 48);
            header.Controls.Add(title); header.Controls.Add(subtitle); header.Controls.Add(tag);

            Panel content = new Panel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(28, 12, 28, 12), BackColor = bg };
            Label intro = LabelText("Pregătește un stick de instalare NOVA", 17F, true, mainText);
            Label explain = LabelText("Verificăm imaginea, selectăm stickul și confirmăm scrierea. Instalatorul va cere destinația și partițiile înainte de prima autentificare.", 9.5F, false, muted); explain.MaximumSize = new Size(780, 42);
            Panel p3 = Card(170);
            step3 = LabelText("03  ·  STICK USB", 9F, true, violet); step3.Location = new Point(22, 18);
            Label desc3 = LabelText("Alege stickul de instalare (minimum 8 GB). Conținutul lui va fi șters.", 9.5F, false, muted); desc3.Location = new Point(22, 42);
            drives = new ComboBox { Location = new Point(22, 70), Width = 535, Height = 34, DropDownStyle = ComboBoxStyle.DropDownList, BackColor = Color.FromArgb(25, 30, 42), ForeColor = mainText, FlatStyle = FlatStyle.Flat, Font = new Font("Segoe UI", 10F) };
            refreshButton = MakeButton("Reîmprospătează", false); refreshButton.Location = new Point(570, 67); refreshButton.Click += async delegate { await RefreshDrives(); };
            drives.SelectedIndexChanged += delegate { writeButton.Enabled = verified && drives.SelectedIndex >= 0 && active == null; };
            Label warning = LabelText("Doar discurile USB identificabile sunt afișate. Discurile de sistem sunt excluse.", 8.5F, false, muted); warning.Location = new Point(22, 111);
            writeButton = MakeButton("Creează stickul NOVA", true); writeButton.Location = new Point(22, 132); writeButton.Height = 36; writeButton.Enabled = false; writeButton.Click += WriteClicked;
#if PREVIEW
            writeButton.Text = "Test UI · fără scriere";
#endif
            p3.Controls.AddRange(new Control[] { step3, desc3, drives, refreshButton, warning, writeButton }); content.Controls.Add(p3);

            Panel p2 = Card(105);
            step2 = LabelText("02  ·  VERIFICĂ IMAGINEA", 9F, true, violet); step2.Location = new Point(22, 18);
            isoState = LabelText("ISO-ul NOVA va fi verificat înainte de scriere.", 9F, false, muted); isoState.Location = new Point(22, 42);
            progressTrack = new Panel { Location = new Point(22, 69), Width = 515, Height = 10, BackColor = Color.FromArgb(35, 42, 58) };
            progressFill = new Panel { Dock = DockStyle.Left, Width = 0, BackColor = blue };
            progressTrack.Controls.Add(progressFill);
            verifyButton = MakeButton("Verifică ISO", false); verifyButton.Location = new Point(570, 51); verifyButton.Click += VerifyClicked;
            cancelButton = MakeButton("Anulează", false); cancelButton.Location = new Point(694, 51); cancelButton.Visible = false; cancelButton.Click += delegate { if (active != null) active.Cancel(); };
            p2.Controls.AddRange(new Control[] { step2, isoState, progressTrack, verifyButton, cancelButton });

            Panel p1 = Card(120);
            step1 = LabelText("01  ·  APLICĂ ISO NOVA", 9F, true, violet); step1.Location = new Point(22, 18);
            isoBox = new TextBox { Location = new Point(22, 42), Width = 540, Height = 34, ReadOnly = true, BackColor = Color.FromArgb(25, 30, 42), ForeColor = mainText, BorderStyle = BorderStyle.FixedSingle, Font = new Font("Segoe UI", 9.5F) };
            browseButton = MakeButton("Alege ISO…", false); browseButton.Location = new Point(570, 38); browseButton.Click += BrowseClicked;
            Label isoHelp = LabelText("Imaginea este validată cu dimensiunea și SHA-256 ale acestei versiuni NOVA.", 8.5F, false, muted); isoHelp.Location = new Point(22, 84);
            p1.Controls.AddRange(new Control[] { step1, isoBox, browseButton, isoHelp });
            TableLayoutPanel stack = new TableLayoutPanel { Dock = DockStyle.Top, Height = 473, ColumnCount = 1, RowCount = 5, BackColor = bg, Margin = new Padding(0), Padding = new Padding(0) };
            stack.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            stack.RowStyles.Add(new RowStyle(SizeType.Absolute, 36F)); stack.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
            stack.RowStyles.Add(new RowStyle(SizeType.Absolute, 120F)); stack.RowStyles.Add(new RowStyle(SizeType.Absolute, 105F)); stack.RowStyles.Add(new RowStyle(SizeType.Absolute, 170F));
            intro.Dock = DockStyle.Fill; explain.Dock = DockStyle.Fill; p1.Dock = DockStyle.Fill; p2.Dock = DockStyle.Fill; p3.Dock = DockStyle.Fill;
            stack.Controls.Add(intro, 0, 0); stack.Controls.Add(explain, 0, 1); stack.Controls.Add(p1, 0, 2); stack.Controls.Add(p2, 0, 3); stack.Controls.Add(p3, 0, 4);
            content.Controls.Add(stack);

            Panel footer = new Panel { Dock = DockStyle.Bottom, Height = 62, Padding = new Padding(28, 10, 28, 8), BackColor = Color.FromArgb(13, 16, 25) };
            status = LabelText("Pregătit · nicio modificare nu se face fără confirmarea ta", 9F, true, blue); status.Location = new Point(28, 11);
            detail = LabelText("NOVA OS 0.2 Preview  ·  Fedora Media Writer helper 5.3.2", 8.5F, false, muted); detail.Location = new Point(28, 34);
#if PREVIEW
            status.Text = "PREVIEW SIGUR · scrierea pe dispozitive este dezactivată"; detail.Text = "Mock USB · nicio partiție sau unitate nu este accesată";
#endif
            footer.Controls.Add(status); footer.Controls.Add(detail);
            TableLayoutPanel root = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 3, BackColor = bg, Margin = new Padding(0), Padding = new Padding(0) };
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 126F)); root.RowStyles.Add(new RowStyle(SizeType.Percent, 100F)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 62F));
            root.Controls.Add(header, 0, 0); root.Controls.Add(content, 0, 1); root.Controls.Add(footer, 0, 2); Controls.Add(root);
            Resize += delegate { tag.Left = Math.Max(400, header.Width - tag.Width - 32); stack.Width = Math.Max(300, content.ClientSize.Width - 40); if (drives != null) drives.Width = Math.Max(260, p3.Width - 190); if (isoBox != null) isoBox.Width = Math.Max(260, p1.Width - 190); if (progressTrack != null) { progressTrack.Width = Math.Max(230, p2.Width - 190); SetProgress(Percent); } };
        }

        private void SetProgress(int value)
        {
            Percent = Math.Max(0, Math.Min(100, value));
            if (progressFill != null && progressTrack != null) progressFill.Width = progressTrack.ClientSize.Width * Percent / 100;
        }

        private void AutoFindIso()
        {
            string beside = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, Release.IsoName);
            string artifact = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "artifacts", Release.IsoName);
            string candidate = File.Exists(beside) ? beside : (File.Exists(artifact) ? artifact : "");
            if (candidate != "") { isoPath = candidate; isoBox.Text = Path.GetFileName(candidate); isoBox.SelectionStart = 0; isoBox.SelectionLength = 0; new ToolTip().SetToolTip(isoBox, candidate); ActiveControl = verifyButton; VerifyClicked(this, EventArgs.Empty); }
        }
        private void BrowseClicked(object sender, EventArgs e)
        {
            using (OpenFileDialog dialog = new OpenFileDialog())
            {
                dialog.Title = "Alege imaginea NOVA OS 0.2 Preview"; dialog.Filter = "Imagine NOVA ISO (*.iso)|*.iso|Toate fișierele (*.*)|*.*"; dialog.CheckFileExists = true;
                if (dialog.ShowDialog(this) == DialogResult.OK) { isoPath = dialog.FileName; isoBox.Text = Path.GetFileName(isoPath); new ToolTip().SetToolTip(isoBox, isoPath); verified = false; writeButton.Enabled = false; isoState.Text = "ISO selectat · verificarea este necesară"; status.Text = "Imaginea trebuie verificată înainte de scriere"; }
            }
        }
        private async void VerifyClicked(object sender, EventArgs e)
        {
            if (active != null) return;
            active = new CancellationTokenSource(); SetBusy(true, "Verific ISO-ul NOVA…"); SetProgress(0); verified = false; writeButton.Enabled = false;
            try
            {
                await MediaWriter.VerifyIsoAsync(isoPath, delegate(long count) { SafeUi(delegate { SetProgress((int)Math.Min(100, count * 100L / Release.IsoBytes)); }); }, active.Token);
                verified = true; SetProgress(100); isoState.Text = "Imagine NOVA verificată · SHA-256 corect"; status.Text = "ISO verificat. Alege stickul USB pentru continuare."; status.ForeColor = blue; writeButton.Enabled = drives.SelectedIndex >= 0;
            }
            catch (OperationCanceledException) { isoState.Text = "Verificare anulată"; status.Text = "Verificarea a fost anulată."; }
            catch (Exception ex) { isoState.Text = "ISO invalid sau inaccesibil"; status.Text = ex.Message; status.ForeColor = Color.Orange; }
            finally { active.Dispose(); active = null; SetBusy(false, null); }
        }
        private async Task RefreshDrives()
        {
            if (active != null) return;
            refreshButton.Enabled = false; writeButton.Enabled = false; drives.Items.Clear(); status.Text = "Caut stickuri USB eligibile…";
            try
            {
                List<UsbDisk> found = await Task.Run(delegate { return DiskInventory.ListEligible(); });
                disks.Clear(); disks.AddRange(found);
                foreach (UsbDisk disk in disks) drives.Items.Add(disk.DisplayName);
                if (drives.Items.Count > 0) drives.SelectedIndex = 0;
                status.Text = drives.Items.Count == 0 ? "Nu a fost găsit niciun stick USB eligibil." : "Alege stickul USB pe care vrei să îl pregătești.";
                detail.Text = drives.Items.Count == 0 ? "Conectează un stick de minimum 8 GB și apasă Reîmprospătează." : "Dispozitivele de sistem, interne sau cu stare necunoscută sunt ascunse.";
            }
            catch (Exception ex) { status.Text = "Nu pot verifica discurile USB: " + ex.Message; status.ForeColor = Color.Orange; }
            finally { refreshButton.Enabled = true; writeButton.Enabled = verified && drives.SelectedIndex >= 0; }
        }
        private void WriteClicked(object sender, EventArgs e)
        {
#if PREVIEW
            if (!verified || drives.SelectedIndex < 0) { MessageBox.Show(this, "Alege și verifică ISO-ul pentru previzualizarea ecranului.", "NOVA Preview", MessageBoxButtons.OK, MessageBoxIcon.Information); return; }
            MessageBox.Show(this, "Modul Preview nu poate accesa sau scrie pe niciun dispozitiv.", "NOVA Preview", MessageBoxButtons.OK, MessageBoxIcon.Information); return;
#else
            if (!verified || drives.SelectedIndex < 0) return;
            UsbDisk selected = disks[drives.SelectedIndex];
            DialogResult answer = MessageBox.Show(this,
                "Se va șterge TOT conținutul de pe:\r\n\r\n" + selected.DisplayName + "\r\n\r\nImagine: NOVA OS 0.2 Preview\r\n\r\nContinuăm?",
                "Confirmă ștergerea stickului USB", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2);
            if (answer != DialogResult.Yes) return;
            WriteConfirmed(selected);
#endif
        }
        private async void WriteConfirmed(UsbDisk selected)
        {
            int writeStage = 0; // 0: helper not invoked, 1: helper invoked, 2: helper announced raw media write
            active = new CancellationTokenSource(); SetBusy(true, "Pregătesc stickul…"); SetProgress(0); writeButton.Enabled = false;
            try
            {
                await MediaWriter.WriteAsync(isoPath, selected, delegate(WriteProgress p)
                {
                    if (p.Phase == "Pornire componentă USB") Interlocked.CompareExchange(ref writeStage, 1, 0);
                    if (p.Phase == "Scriere") Interlocked.Exchange(ref writeStage, 2);
                    SafeUi(delegate
                    {
                        status.Text = p.Phase + (p.Total > 0 ? " · " + (p.Bytes * 100L / p.Total).ToString() + "%" : "");
                        if (p.Total > 0) SetProgress((int)Math.Min(100, Math.Max(0, p.Bytes * 100L / p.Total)));
                        if (!String.IsNullOrEmpty(p.Detail)) detail.Text = p.Detail;
                    });
                }, active.Token);
                SetProgress(100); status.ForeColor = blue; status.Text = "Stickul NOVA a fost scris și verificat."; detail.Text = "Repornește laptopul și alege USB Boot din meniul de pornire.";
                MessageBox.Show(this, "Stickul NOVA este gata. Repornește laptopul și alege pornirea de pe USB. Instalarea îți va arăta discurile și partițiile înainte de aplicarea modificărilor.", "NOVA USB gata", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (OperationCanceledException)
            {
                int stage = Interlocked.CompareExchange(ref writeStage, 0, 0);
                status.Text = WriteOutcome.CancelStatus(stage);
                status.ForeColor = Color.Orange;
                detail.Text = WriteOutcome.CancelDetail(stage);
            }
            catch (Exception ex)
            {
                int stage = Interlocked.CompareExchange(ref writeStage, 0, 0);
                status.Text = ex.Message; status.ForeColor = Color.Orange;
                detail.Text = WriteOutcome.FailureDetail(stage);
            }
            finally { active.Dispose(); active = null; SetBusy(false, null); writeButton.Enabled = verified && drives.SelectedIndex >= 0; }
        }
        private void SetBusy(bool busy, string message)
        {
            verifyButton.Enabled = !busy; browseButton.Enabled = !busy; refreshButton.Enabled = !busy; drives.Enabled = !busy; cancelButton.Visible = busy; writeButton.Enabled = !busy && verified && drives.SelectedIndex >= 0;
            if (message != null) { status.Text = message; status.ForeColor = blue; }
        }
        private void SafeUi(Action action)
        {
            if (IsDisposed) return;
            if (InvokeRequired) { try { BeginInvoke(action); } catch { } } else action();
        }
    }

    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            if (args.Length > 0 && args[0] == "/self-test") { SelfTest.Run(); return; }
#if PREVIEW
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new NovaForm());
#else
            if (!IsAdministrator())
            {
                try { Process.Start(new ProcessStartInfo(Assembly.GetExecutingAssembly().Location) { UseShellExecute = true, Verb = "runas" }); }
                catch (Exception) { MessageBox.Show("NOVA Media Creation Tool are nevoie de confirmarea Administratorului pentru scrierea unui stick USB.", "NOVA", MessageBoxButtons.OK, MessageBoxIcon.Information); }
                return;
            }
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new NovaForm());
#endif
        }
        private static bool IsAdministrator()
        {
            WindowsIdentity identity = WindowsIdentity.GetCurrent();
            return new WindowsPrincipal(identity).IsInRole(WindowsBuiltInRole.Administrator);
        }
    }

    internal static class SelfTest
    {
        public static void Run()
        {
            if (Quote("C:\\NOVA path\\one.iso") != "\"C:\\NOVA path\\one.iso\"") throw new Exception("Argument quoting failed");
            if (MediaWriter.BuildHelperArguments("C:\\NOVA path\\one.iso", 17) != "write \"C:\\NOVA path\\one.iso\" 17") throw new Exception("Fedora helper command arguments failed");
            string zip = Assembly.GetExecutingAssembly().GetManifestResourceNames().FirstOrDefault(n => n == "NOVA.Media.VendorZip");
            if (zip == null) throw new Exception("Embedded Fedora package missing");
            using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(zip))
            using (SHA256 sha = SHA256.Create())
                if (BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant() != Release.VendorZipSha256) throw new Exception("Embedded Fedora archive checksum failed");
            if (Release.IsoBytes != new FileInfo(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "artifacts", Release.IsoName)).Length) throw new Exception("ISO length differs");
            if (WriteOutcome.FailureDetail(0).Contains("date incomplete") || !WriteOutcome.FailureDetail(2).Contains("date incomplete") ||
                !WriteOutcome.FailureDetail(1).Contains("verifică stickul")) throw new Exception("USB failure status does not match the write stage");
            if (VendorPackage.HasWriteAccess(FileSystemRights.ReadAndExecute) ||
                VendorPackage.HasWriteAccess(unchecked((FileSystemRights)(int)0x80000000))) throw new Exception("Read-only cache permissions were incorrectly classified as writable");
            if (!VendorPackage.HasWriteAccess(FileSystemRights.Modify) ||
                !VendorPackage.HasWriteAccess((FileSystemRights)0x40000000) ||
                !VendorPackage.HasWriteAccess((FileSystemRights)0x10000000) ||
                !VendorPackage.HasWriteAccess(FileSystemRights.FullControl)) throw new Exception("Writable cache permissions were not detected");
            MediaWriter.VerifyIsoAsync(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "artifacts", Release.IsoName), null, CancellationToken.None).GetAwaiter().GetResult();
            Console.WriteLine("NOVA Media Creator self-test passed: Fedora helper command and argument quoting, read-only/write ACL classification, embedded vendor SHA-256, NOVA ISO SHA-256. No disks were enumerated or modified.");
        }
        private static string Quote(string value)
        {
            StringBuilder b = new StringBuilder("\""); int slashes = 0;
            foreach (char c in value) { if (c == '\\') { slashes++; continue; } if (c == '"') { b.Append('\\', slashes * 2 + 1); b.Append('"'); slashes = 0; continue; } b.Append('\\', slashes); slashes = 0; b.Append(c); }
            b.Append('\\', slashes * 2); b.Append('"'); return b.ToString();
        }
    }
}
