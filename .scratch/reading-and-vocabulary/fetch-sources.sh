#!/bin/sh
# Fetch the three upstream word lists that build-word-list.py reads, pinned to the
# commits they were taken from on 21 September 2026, so the bundled list can be
# rebuilt byte for byte. See PersonalSchedule/Vocabulary/SOURCE.md.
set -eu

LEON=b14cf7395ec618ba9f83234e751f32c1be839a6d
CLEM=f3dc9d12ae00d04fa3676b0bd4c43cd58de2c264
DRK=7ac65bf1a6387d35f1ade478906172a19311c7f9

mkdir -p sources
cd sources

fetch() {
    echo "  $3"
    curl -sSfL -o "$3" "https://raw.githubusercontent.com/$1/$2/$4"
}

# Membership: which words are at which level.
for level in 4 5; do
    fetch leonsilicon/hsk2.0 "$LEON" "leon$level.txt" "data/HSK2.0/HSK2.0_words_level$level.txt"
done

# Readings: the pinyin and senses HSK means, already chosen per level.
for level in 1 2 3 4 5 6; do
    fetch clem109/hsk-vocabulary "$CLEM" "clem$level.json" "hsk-vocab-json/hsk-level-$level.json"
done

# Fallback: words clem109 doesn't carry.
fetch drkameleon/complete-hsk-vocabulary "$DRK" complete.json complete.json

echo "fetched into $(pwd)"
