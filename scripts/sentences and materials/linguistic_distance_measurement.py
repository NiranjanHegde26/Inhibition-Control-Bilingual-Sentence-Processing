"""
    Title:    Linguistic Distance Measurement Script
    Project:  Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self Paced Reading Approach
    OSF:      https://osf.io/uyvxw
    Author:   Niranjana Hegde Bhimanakone Satyanarayana
    Created:  07/09/2025
    Resources:
        epitran: https://github.com/dmort27/epitran (Good for IPA string transcription) 
        python-Levenshtein: https://github.com/rapidfuzz/python-Levenshtein  (Good for orthographic distance measures)
        panphon: https://github.com/dmort27/panphon (Good for phonetic distance measures)      
    Description:
        This script calculates the orthographic and phonetic distance of English and German forms 
        of interlingual homographs using the IPA forms.
    Note: 
        Installation of packages should follow the detailed instruction from README files available at each repository.
"""

import epitran
from epitran.backoff import Backoff
import locale
import panphon.distance
dst = panphon.distance.Distance()
import pandas as pd
from Levenshtein import distance as ld

# Set locale to UTF-8
try:
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
except locale.Error:
    locale.setlocale(locale.LC_ALL, 'C.UTF-8')
    
epi_en = epitran.Epitran('eng-Latn')
epi_de = epitran.Epitran('deu-Latn')
backoff = Backoff(['deu-Latn', 'eng-Latn'], cedict_file='cedict_1_0_ts_utf-8_mdbg.txt')

def calculate_phonetic_distance(str1, str2):
    # This can be calculated using Feature Edit distance
    # Uses the words as is (and not IPA strings)
    return dst.feature_edit_distance(str1, str2)  

def calculate_orthographic_distance(str1, str2):
    # This can be calculated using Levenstein Distance
    return ld(str1, str2)

def generate_English_IPA_string(word):
    # Transliterates the English word to its corresponding IPA string
    try:
        ipa_string = epi_en.transliterate(word)
        return ipa_string
    except Exception as e:
        print(f"Error phonemizing {word}: {e}")
        return None
    
def generate_German_IPA_string(word):
    # Transliterates the German word to its corresponding IPA string
    try:
        ipa_string = epi_de.transliterate(word)
        return ipa_string
    except Exception as e:
        print(f"Error phonemizing {word}: {e}")
        return None
    
def normalise_phonetic_distance(str1, str2, dist):
    # Normalises the phonetic distances by accounting for the phonemic differences between the 2 forms of interlingual homograph.
    # Note: This normalization is done on per-item basis. Additional normalization is required
    
    # trans_list: returns a list of IPA unicode strings, each of which is a phoneme
    # Thus the normalization is now based on no. of phonemes
    # Referred from https://github.com/dmort27/epitran?tab=readme-ov-file#the-backoff-class
    
    str1Tokens = backoff.trans_list(str1)
    str2Tokens = backoff.trans_list(str2)
    return dist / max(len(str1Tokens), len(str2Tokens)) 

def normalise_orthographic_distance(str1, str2, dist):
    # Normalises the distance by accounting for the character differences between the 2 forms of interlingual homograph.
    # Note: This normalization is done on per-item basis. Additional normalization is required
    return dist / max(len(str1), len(str2)) 

items_file = "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\materials\\items.csv"
results_file = "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\materials\\itemsWithDistances.csv"

df = pd.read_csv(items_file)
df['English IPA'] = df['EnglishWord'].apply(lambda row: generate_English_IPA_string(row))
df['German IPA'] = df['GermanWord'].apply(lambda row: generate_German_IPA_string(row))
df['Phonetic Distance'] = df.apply(lambda row: calculate_phonetic_distance(row['English IPA'], row['German IPA']), axis=1)
df['Orthographic Distance'] = df.apply(lambda row: calculate_orthographic_distance(row['EnglishWord'], row['GermanWord']), axis=1)
df['Phonetic Distance Normalised'] = df.apply(lambda row: normalise_phonetic_distance(row['English IPA'], row['German IPA'], row['Phonetic Distance']), axis=1)
df['Orthographic Distance Normalised'] = df.apply(lambda row: normalise_orthographic_distance(row['English IPA'], row['German IPA'], row['Orthographic Distance']), axis=1)
df.to_csv(results_file)
