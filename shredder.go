package main

import (
	"crypto/rand"
	"fmt"
	"os"
)

func Shred(path string) error {

	file, err := os.OpenFile(path, os.O_WRONLY, 0)
	if err != nil {
		return err
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return err
	}
	size := info.Size()

	for i := 0; i < 3; i++ {
		_, err = file.Seek(0, 0)
		if err != nil {
			return err
		}

		randomData := make([]byte, size)
		_, err = rand.Read(randomData)
		if err != nil {
			return err
		}

		_, err = file.Write(randomData)
		if err != nil {
			return err
		}
	}

	file.Close()
	err = os.Remove(path)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("To use: go run shredder.go <file path>")
		return
	}

	filePath := os.Args[1]
	err := Shred(filePath)
	if err != nil {
		fmt.Println("Error while trying to", err)
	} else {
		fmt.Println("File shredded!")
	}
}
