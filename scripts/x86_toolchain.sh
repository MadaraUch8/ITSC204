#! /bin/bash

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022
# code modification suggested by Arsel Junior


if [ $# -lt 1 ]; then
  echo "Usage:"
  echo ""
  echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
  echo ""
  echo "-v | --verbose                Show some information about steps performed."
  echo "-g | --gdb                    Run gdb command on executable."
  echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
  echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
  echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
  echo "-64| --x86-64                 Compile for 64bit (x86-64) system."
  echo "-o | --output <filename>      Output filename."
  exit 1
fi

POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=False
QEMU=False
BREAK="_start"
RUN=False

for arg in "$@"; do
  case $arg in
    -g|--gdb)
      GDB=True
      ;;
    -o|--output)
      OUTPUT_FILE="${2:-}"
      shift # past argument
      ;;
    -v|--verbose)
      VERBOSE=True
      ;;
    -64|--x84-64)
      BITS=True
      ;;
    -q|--qemu)
      QEMU=True
      ;;
    -r|--run)
      RUN=True
      ;;
    -b|--break)
      BREAK="${2:-_start}"
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $arg"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$arg") # save positional arg
      ;;
  esac
done

if [[ ! -f ${POSITIONAL_ARGS[0]} ]]; then
  echo "Specified file does not exist"
  exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then
  OUTPUT_FILE=${POSITIONAL_ARGS[0]%.*}
fi

if [ "$VERBOSE" == "True" ]; then
  echo "Arguments being set:"
  echo "  GDB = ${GDB}"
  echo "  RUN = ${RUN}"
  echo "  BREAK = ${BREAK}"
  echo "  QEMU = ${QEMU}"
  echo "  Input File = ${POSITIONAL_ARGS[0]}"
  echo "  Output File = $OUTPUT_FILE"
  echo "  Verbose = $VERBOSE"
  echo "  64 bit mode = $BITS"
  echo ""

  echo "NASM started..."
fi

if [ "$BITS" == "True" ]; then
  nasm -f elf64 "${POSITIONAL_ARGS[0]}" -o "$OUTPUT_FILE.o" && echo ""
elif [ "$BITS" == "False" ]; then
  nasm -f elf "${POSITIONAL_ARGS[0]}" -o "$OUTPUT_FILE.o" && echo ""
fi

if [ "$VERBOSE" == "True" ]; then
  echo "NASM finished"
  echo "Linking ..."
fi

if [ "$BITS" == "True" ]; then
  ld -m elf_x86_64 "$OUTPUT_FILE.o" -o "$OUTPUT_FILE" && echo ""
elif [ "$BITS" == "False" ]; then
  ld -m elf_i386 "$OUTPUT_FILE.o" -o "$OUTPUT_FILE" && echo ""
fi

if [ "$VERBOSE" == "True" ]; then
  echo "Linking finished"
fi

if [ "$QEMU" == "True" ]; then
  echo "Starting QEMU ..."
  echo ""
  if [ "$BITS" == "True" ]; then
    qemu-x86_64 "$OUTPUT_FILE" && echo ""
  elif [ "$BITS" == "False" ]; then
    qemu-i386 "$OUTPUT_FILE" && echo ""
  fi
  exit 0
fi

if [ "$GDB" == "True" ]; then
  gdb_params=()
  gdb_params+=(-ex "b ${BREAK}")

  if [ "$RUN" == "True" ]; then
    gdb_params+=(-ex "r")
  fi

  gdb "${gdb_params[@]}" "$OUTPUT_FILE"
fi
