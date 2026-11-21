# haksaeng story writer — no-gradle APK build (aapt2 + javac + d8 + apksigner)
$ErrorActionPreference='Stop'

$sdk   ="$env:LOCALAPPDATA\Android\Sdk"
$bt    ="$sdk\build-tools\36.0.0"
$plat  =(Get-ChildItem "$sdk\platforms" -Filter 'android-*' | Sort-Object Name)[-1]
$jar   ="$($plat.FullName)\android.jar"
$jbr   ="C:\Program Files\Android\Android Studio\jbr\bin"
$root  =$PSScriptRoot
Set-Location $root

# refresh webapp asset from mockup (single source of truth)
New-Item -ItemType Directory -Force assets | Out-Null
Copy-Item "$root\..\mockup\story_writer.html" assets\story_writer.html -Force
Write-Host "[1/8] asset refreshed"

# clean
Remove-Item build,gen -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force build,gen | Out-Null

# 1. compile resources
& "$bt\aapt2.exe" compile --dir res -o build\res.zip | Write-Host
Write-Host "[2/8] resources compiled"

# 2. link -> base apk + R.java
& "$bt\aapt2.exe" link -o build\base.apk -I $jar `
  --manifest AndroidManifest.xml -A assets --java gen `
  --min-sdk-version 26 --target-sdk-version 34 `
  --version-code 1 --version-name 1.0 `
  --auto-add-overlay build\res.zip | Write-Host
Write-Host "[3/8] base apk linked"

# 3. javac (JBR)
& "$jbr\javac.exe" --release 8 -classpath $jar -d build\classes `
  gen\com\eunhagames\storywriter\R.java `
  java\com\eunhagames\storywriter\MainActivity.java | Write-Host
Write-Host "[4/8] java compiled"

# 4. d8 dex (run d8 jar with the JBR java, not the ancient PATH java 8)
$classList=Get-ChildItem build\classes -Recurse -Filter *.class | % FullName
Push-Location build\classes
$relArgs=$classList | % { $_.Substring(("$root\build\classes\").Length) }
New-Item -ItemType Directory -Force "$root\build\dex" | Out-Null
& "$jbr\java.exe" -cp "$bt\lib\d8.jar" com.android.tools.r8.D8 `
  --release --lib $jar --min-api 26 --output "$root\build\dex" $relArgs | Write-Host
Pop-Location
Write-Host "[5/8] dexed"

# 5. inject classes.dex into apk
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fs=[IO.File]::Open("$root\build\base.apk",[IO.FileMode]::Open)
$zap=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Update)
$entry=$zap.CreateEntry('classes.dex',[IO.Compression.CompressionLevel]::Optimal)
$in =[IO.File]::OpenRead("$root\build\dex\classes.dex")
$out=$entry.Open(); $in.CopyTo($out); $out.Dispose(); $in.Dispose()
$zap.Dispose(); $fs.Dispose()
Write-Host "[6/8] classes.dex packaged"

# 6. zipalign
& "$bt\zipalign.exe" -f 4 build\base.apk build\aligned.apk | Write-Host
Write-Host "[7/8] aligned"

# 7. sign (debug keystore — Android Studio made one already)
$ks="$env:USERPROFILE\.android\debug.keystore"
if(!(Test-Path $ks)){
  & "$jbr\keytool.exe" -genkeypair -keystore $ks -storepass android `
    -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 `
    -validity 10000 -dname "CN=Android Debug,O=Android,C=US" | Write-Host
}
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android `
  --ks-key-alias androiddebugkey --key-pass pass:android `
  --out "$root\StoryWriter-v1.0.apk" build\aligned.apk | Write-Host
& "$bt\apksigner.bat" verify --print-certs "$root\StoryWriter-v1.0.apk" | Write-Host
Write-Host "[8/8] SIGNED -> StoryWriter-v1.0.apk"

Get-Item "$root\StoryWriter-v1.0.apk" | Select Name,@{n='KB';e={[math]::Round($_.Length/1KB)}}
