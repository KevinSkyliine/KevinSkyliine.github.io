$port = 8080
$path = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Serveur Web Lumina démarré !" -ForegroundColor Green
Write-Host " Ouvrez votre navigateur à l'adresse :" -ForegroundColor White
Write-Host " http://localhost:$port/" -ForegroundColor Yellow
Write-Host " Appuyez sur Ctrl+C dans cette fenêtre pour arrêter." -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan

# Ouvrir le navigateur automatiquement
Start-Process "http://localhost:$port/"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }
        
        # Remplacer les slashs par des antislashs pour Windows
        $urlPath = $urlPath -replace '/', '\'
        $filePath = Join-Path $path $urlPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html" }
                ".css"  { "text/css" }
                ".js"   { "application/javascript" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".gif"  { "image/gif" }
                ".svg"  { "image/svg+xml" }
                ".json" { "application/json" }
                ".ico"  { "image/x-icon" }
                default { "application/octet-stream" }
            }
            $response.ContentType = $contentType
            
            try {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            } catch {
                $response.StatusCode = 500
            }
        } else {
            $response.StatusCode = 404
            $content = [System.Text.Encoding]::UTF8.GetBytes("404 - Fichier introuvable")
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
        }
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
