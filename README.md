# Some Handy Scripts

## Overview

| Script | Brief Description | Link to README |
| :----- | :---------------- | :------------ |
| [`convert_cmuics_to_ics.py`](convert_cmuics_to_ics.py) | Convert the CMU<sup>TM</sup> ICS calendar file to the universal calendar file format. | [README](#convert_cmuics_to_icspy) |
| [`install_llvm_from_source.sh`](install_llvm_from_source.sh) | Download, configure, build, and install LLVM. | [README](#install_llvm_from_sourcesh) |

## Script README

### [`convert_cmuics_to_ics.py`](convert_cmuics_to_ics.py)

#### This script converts a CMU-flavored ICS calendar to standard ICS format.

#### What is CMU-flavored ICS?
CMU's "ICS" format concatenates everything into a single line. For example:

```
BEGIN:VCALENDAR VERSION:2.0 PRODID:-//hacksw/handcal//NONSGML v1.0//EN BEGIN:VEVENT DTSTART:....
```

Whereas the universally recognized calendar file format looks like:

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN

BEGIN:VEVENT
DTSTART:....
```

#### Usage

```console
Usage: ./convert_cmuics_to_ics.py [-h] -i INPUT [-o OUTPUT] [--overwrite]
    -h, --help      show this help message and exit
    -i, --input     Input file path.
    -o, --output    Output file path.
    --overwrite     Overwrite the input file.
                    When this flag is specified the output file path is ignored.
```

For example, to convert `calendar.ics` in-place, run:
```console
$ ./convert_cmuics_to_ics.py -i calendar.ics --overwrite
```

#### Requirements

Python 3 is all you need.

### [`install_llvm_from_source.sh`](install_llvm_from_source.sh)

#### This script downloads, configures, builds, and installs LLVM from LLVM Project.

#### Usage

```console
Usage: ./install_llvm_from_source.sh -i install_dir -v version [-t build_type] [-j num_threads] [additional CMake defines]
	-i	[REQUIRED] path to the directory to install LLVM
	  		this directory need not exist
	-v	[REQUIRED] version of LLVM to install
	  		this should be in the format of x.x.x
	-t	[OPTIONAL] LLVM build type (default: RelWithDebInfo)
	  		this can be one of {Release, Debug, RelWithDebInfo, MinSizeRel}
    -j  [OPTIONAL] number of threads to use (default: $(nproc))
	  	[OPTIONAL] all additional CMake defines should be in the key=val format seperated by space
	  		see https://llvm.org/docs/CMake.html#options-and-variables for available CMake variables
```

For example, to install LLVM 16.0.0 to `$(pwd)/LLVM_16.0.0` using `Release` build with assertions enabled, run:
```console
$ ./install_llvm_from_srouce.sh -i LLVM_16.0.0 -v 16.0.0 -t Release LLVM_ENABLE_ASSERTIONS=ON
```

#### Requirements

Working internet connection, build tools, and CMake.
[See LLVM's requirements on CMake version](https://llvm.org/docs/CMake.html#quick-start).
