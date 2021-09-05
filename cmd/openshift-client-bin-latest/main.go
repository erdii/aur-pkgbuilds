package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"

	"golang.org/x/mod/semver"
)

func main() {
	version, err := getLatestAvailableV4Version()
	if err != nil {
		panic(err)
	}

	fmt.Println(version)
}

const latestV4ReleaseTxtURL = "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/release.txt"

var (
	releaseVersionRegex        = regexp.MustCompile(`Version:\s{0,}(4\.\d{1,}\.\d{1,})`)
	errCouldNotExtractVersion  = errors.New("could not extract version string from release file")
	errCouldNotValidateVersion = errors.New("could not validate semver string from release file")
)

// fetches the latest release.txt and extracts/validates the version string
func getLatestAvailableV4Version() (string, error) {
	resp, err := http.Get(latestV4ReleaseTxtURL)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	matches := releaseVersionRegex.FindStringSubmatch(string(body))

	// the 2nd match should be the version number
	if len(matches) < 2 {
		return "", errCouldNotExtractVersion
	}

	version := strings.Trim(matches[1], " \n\t\r")

	if !semver.IsValid(fmt.Sprintf("v%s", version)) {
		return "", errCouldNotValidateVersion
	}

	return version, nil
}
