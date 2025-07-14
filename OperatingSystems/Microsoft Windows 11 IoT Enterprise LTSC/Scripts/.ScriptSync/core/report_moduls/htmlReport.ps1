$ReportPath = ".\output\FullReport.html"
Copy-Item -Path ".\_validation\fullReport" -Destination $ReportPath -Force
$htmlContent = @"
	<script>
		const report = $jsonString
		$scritpContent
	</script>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Append
