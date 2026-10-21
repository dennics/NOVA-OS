# NOVA OS 0.2 Preview — funcții și limite

Această versiune rămâne un preview pentru VM. Imaginea se instalează offline prin
Anaconda; alegerea discului, partițiilor și formatării se face în instalator,
înainte de prima autentificare. Testele pe laptopul HP și scrierea pe USB fizic
nu sunt încă probe de acceptare.

| Funcție | Comportament implementat | Limită explicită |
| --- | --- | --- |
| Smart Compatibility | Dolphin deschide `.exe` în dialogul NOVA. Verifică structura PE, arhitectura și indicii offline pentru câteva versiuni Linux native; Wine pornește numai la cererea utilizatorului. Poate folosi un mediu Wine separat pentru fiecare cale de program. | Nu garantează rularea și nu verifică identitatea editorului. Un program Wine are acces la fișierele contului. |
| Update Engine | Settings arată imaginea bootc, starea versiunii pregătite și disponibilitatea rollbackului. Operațiile `check`, `download`, `stage` și `rollback` sunt limitate la un ajutor fix autorizat prin polkit; repornirea cere confirmare. | ISO-ul offline indică `nova.invalid/nova:preview`, deci descărcarea online este dezactivată până există un registru NOVA publicat și validat. Nu adăugăm o adresă fictivă. |
| Profile Manager | Eco, Balanced și Gaming cer profilurile `power-saver`, `balanced` și `performance` serviciului de energie al sistemului. GameMode este inclus pentru jocuri lansate cu `gamemoderun`. | Dacă hardware-ul sau serviciul nu suportă profilul, se afișează eroarea; Gaming nu promite FPS mai mare și nu oprește automat sarcinile din fundal. |
| Driver Center | Detectează GPU-uri PCI NVIDIA, AMD și Intel, afișează ID-ul și driverul kernel activ. Driverele deschise sunt actualizate odată cu imaginea sistemului. | Instalarea driverului NVIDIA proprietar așteaptă o sursă de încredere și testele Secure Boot; NVIDIA App pentru Windows nu este utilizată. |
| Opera GX | Este browserul implicit pentru HTTP, HTTPS și HTML, inclus în imaginea de testare din pachetul Linux fixat prin SHA-256. | Distribuirea publică trebuie verificată în raport cu licența Opera; includerea într-un ISO local de probă nu dovedește drepturi de redistribuire. |
| Arhive | Ark este asociat cu ZIP, RAR și 7z; sunt incluse `7zip` și `unar`. | WinRAR și crearea de arhive RAR nu sunt incluse. Unele arhive criptate sau deteriorate pot eșua. |

## Profiluri de performanță

`Settings → Performanță` oferă Eco / Balanced / Gaming și arată profilul activ.
Selectarea se transmite serviciului de energie și poate fi refuzată dacă acesta
nu este disponibil. GameMode se aplică **pe durata procesului lansat cu**
`gamemoderun`; alegerea Gaming nu schimbă automat prioritățile tuturor
proceselor. Conectarea automată a lansatoarelor de jocuri și testele FPS rămân
pentru etapa dedicată gamingului.

## Actualizări și recuperare

`Settings → Actualizări` citește starea bootc fără drepturi de administrator.
Pentru operațiile care schimbă sistemul, ajutorul root acceptă exclusiv cele
patru acțiuni fixe; nu primește comenzi sau adrese de registru de la interfață.
Sursa locală simbolică este refuzată. Rollbackul poate selecta versiunea
anterioară numai când aceasta există. Revenirea nu garantează compatibilitatea
configurărilor din `/etc`; scenariul cu două versiuni trebuie retestat în VM
pentru 0.2 înainte de a declara recuperarea acceptată.

## Teste de acceptare suplimentare

1. Deschide din Dolphin un PE x86/x64 valid, un PE ARM64 și un fișier invalid;
   confirmă că Wine nu pornește fără acțiune explicită. Testează mediul separat
   și mediul comun, apoi verifică dosarele Wine rezultate.
2. Confirmă că Settings nu încearcă descărcarea de la `nova.invalid`, că ajutorul
   refuză operații necunoscute și că polkit cere autorizare. Pe două imagini
   locale, verifică actualizarea, repornirea și rollbackul cu fișiere persistente.
3. Compară profilul afișat cu serviciul de energie, inclusiv cazul în care
   `performance` nu este oferit. Testează un proces pornit cu GameMode.
4. Compară GPU-ul și driverul afișate cu `/sys/bus/pci/devices`; pe hardware real
   verifică separat AMD, Intel și NVIDIA.
5. Verifică implicit Opera GX și extragerea unor arhive mici ZIP, 7z și RAR,
   inclusiv conținutul obținut.

Rezultatele concrete ale candidatului sunt în [VALIDATION.md](VALIDATION.md).
