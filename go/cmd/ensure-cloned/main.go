package main

import (
	"context"
	"errors"
	"fmt"
	stdlog "log"
	"os"
	"path"

	git "github.com/go-git/go-git/v5"
	"github.com/go-logr/stdr"
	yaml "gopkg.in/yaml.v3"
)

type packageList []string

func readPackageFile(name string) (packageList, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}

	pkgs := packageList{}
	if err := yaml.NewDecoder(f).Decode(&pkgs); err != nil {
		return nil, err
	}

	return pkgs, nil
}

func ensureClonedPackage(ctx context.Context, folder, name string) (*git.Repository, error) {
	repo, err := git.PlainCloneContext(ctx, path.Join(folder, name), false, &git.CloneOptions{
		URL: fmt.Sprintf("ssh://aur@aur.archlinux.org/%s", name),
	})

	// Suppress error if repo was already cloned and instead pull to ensure repo freshness.
	if errors.Is(err, git.ErrRepositoryAlreadyExists) {
		repo, err := git.PlainOpen(path.Join(folder, name))
		if err != nil {
			return nil, err
		}

		worktree, err := repo.Worktree()
		if err != nil {
			return nil, err
		}

		// Clean up repo.
		if err := worktree.Clean(&git.CleanOptions{}); err != nil {
			return nil, err
		}

		err = worktree.PullContext(ctx, &git.PullOptions{})
		// Suppress error if repo is already up-to-date.
		if errors.Is(err, git.NoErrAlreadyUpToDate) {
			return repo, nil
		}
		return repo, err
	}

	return repo, err
}

func main() {
	stdr.SetVerbosity(1)
	log := stdr.NewWithOptions(stdlog.New(os.Stderr, "", stdlog.LstdFlags), stdr.Options{LogCaller: stdr.All})
	log = log.WithName("check")

	pkgs, err := readPackageFile("./packages.yaml")
	if err != nil {
		log.Error(err, "Failed to read package list.")
		os.Exit(1)
	}

	log.Info("Read package list.", "pkgs", pkgs)

	folder := "./packages"

	if err := os.MkdirAll(folder, 0750); err != nil {
		log.Error(err, "Failed to create working folder.")
		os.Exit(2)
	}

	ctx := context.Background()

	for _, pkg := range pkgs {
		log.Info("Ensuring up-to-date repo clone for package.", "pkg", pkg)

		repo, err := ensureClonedPackage(ctx, folder, pkg)
		if err != nil {
			log.Error(err, "Failed to ensure clone of package.",
				"folder", folder,
				"pkg", pkg,
			)
			os.Exit(3)
		}

		head, err := repo.Head()
		if err != nil {
			log.Error(err, "Failed to get HEAD of repo.",
				"folder", folder,
				"pkg", pkg)
			os.Exit(4)
		}

		log.Info("Ensured up-to-date repo clone for package.", "pkg", pkg, "head", head.Hash())
	}
}
