# Build site from source text
build:
	pwsh -NoProfile ./instructron/build.ps1

# Clean generated output
clean:
	rm -rf docs

# Serve locally using VS Code Live Server
serve:
	open -a "Visual Studio Code" . && sleep 1 && open http://localhost:5500/docs/

open:
	open https://aha43.github.io/aha-astrolab/

# Rebuild site and preview
preview: clean build serve

what:
	pwsh -NoProfile ./instructron/what.ps1

# layout:
# 	pwsh -NoProfile ./instructron/get-layout.ps1

# ensure:
# 	pwsh -NoProfile ./instructron/ensure-layout.ps1
