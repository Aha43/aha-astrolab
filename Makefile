# Build site from source text
build:
	pwsh -NoProfile ./build.ps1

# Clean generated output
clean:
	rm -rf docs

# Serve locally using VS Code Live Server
serve:
	open -a "Visual Studio Code" . && sleep 1 && open http://localhost:5500/docs/

# Rebuild site and preview
preview: clean build serve
