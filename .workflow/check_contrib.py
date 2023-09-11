import git
import os

from git.types import sys

script_dir = os.path.dirname(os.path.realpath(__file__))

repo = git.Repo(search_parent_directories=True)
repo_dir = repo.working_dir
assert repo_dir is not None

commiters = set()

# Iterate through all commits in the repository
for commit in repo.iter_commits():
    commiters.add(commit.committer.name)

# Convert the set to a list if needed
commiters_list = list(commiters)

# Print the list of committers

contributor_file_rel = "docs/CONTRIBUTORS"
contributor_file = os.path.abspath(os.path.join(repo_dir, contributor_file_rel))

contributors_from_file = []
try:
    with open(contributor_file, "r") as file:

        start_collecting = False
        for line in file:
            if start_collecting:
                if line.strip():
                    contributors_from_file.append(line.strip())
            elif line.strip().startswith("# List of people who contributed to this repository:"):
                start_collecting = True
except FileNotFoundError:
    print(f"The file '{contributor_file}' does not exist.")
    sys.exit(1)
except Exception as e:
    print(f"An error occurred: {str(e)}")
    sys.exit(1)

for commiter in commiters_list:
    if commiter not in contributors_from_file:
        print(f"[ERROR] Commiter: {commiter} is not in contributor file {contributor_file_rel}\nPlease add your name to the list of Contributors")
        sys.exit(1)
