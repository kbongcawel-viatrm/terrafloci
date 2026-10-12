# Authenticate with GitHub.
gh auth login

GIT_DIR=terrafloci

# Create the local workspace.
echo "Creating terrafloci folder..."
mkdir -p $GIT_DIR && cd $GIT_DIR

# Place the downloaded README in this directory, then rename it.
echo "Moving files to the folder..."
mv ./README.md $GIT_DIR
mv ./scripts $GIT_DIR

# Initialize Git and create the GitHub repository.
cd $GIT_DIR
echo "Running git init and adding committing the files..."
git init -b main
git add .

# Commit after reviewing the staged README.
git commit -m "scripts and docs: document terrafloci workspace environment"

# Create the GitHub repository; choose visibility when prompted.
echo "creating the repository and pushing the first commit..."
gh repo create terrafloci --source=. --remote=origin --push
echo "Done!"

echo "Getting repo and branch info..."
git branch -a
git remote -v
git status
git log

echo "Closing now"
exit 0;
