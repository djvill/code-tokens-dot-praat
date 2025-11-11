## CodeTokens.praat
## Dan Villarreal (d.vill@pitt.edu)
##
## With a folder of TextGrids+sound files and a csv file, creates an
## interface for coding tokens interactively that populates the csv.
## Meant to be used with APLS version 0.4.1 (https://apls.pitt.edu).
##
## To use:
## 1. Search for tokens of interest (https://djvill.github.io/APLS/doc/search)
## 2. _CSV Export_ with "Include annotation start/end times:" set to "(always) if manually, automatically, or default aligned"
##    - Keep all default field/layer selections
## 3. _Utterance Export_ with all defaults
## 4. _Audio Export_ with all defaults
## 5. Unzip the two .zip folders downloaded in the previous two steps
## 6. Make note of where these files and folders are saved on your computer
## 7. Run this script

##Require Praat version >= 6.4.32 for random_initializeWithSeedUnsafelyButPredictably()
@validateVersion: "6.4.32"

##Parameters
##Use GUI form to specify script parameters? (0 to use parameters specified in the following lines)
use_form = 1
##Search name
search_name$ = ""
@search_name_to_filename: search_name$
search_name$ = search_name_to_filename.search_name$
##Directory containing input csv file, and subfolders with TextGrids & sound files
windows_home$ = environment$("USERPROFILE")
if windows_home$ <> ""
  in_dir$ = replace$(windows_home$, "\", "/", 0) + "/Downloads"
else
  in_dir$ = environment$("HOME") + "/Downloads"
endif
##Directory containing TextGrids
tg_dir$ = in_dir$ + "/fragments_" + search_name$ + "/"
##Directory containing sound files
wav_dir$ = in_dir$ + "/media_" + search_name$ + "/"
##Input csv file with tokens to code
in_csv$ = in_dir$ + "/" + "results_" + search_name$ + ".csv"
##Write csv file for saving coded tokens?
write = 1
##Suffix on output csv file
out_csv_suffix$ = "_coded"
##Output csv file for saving coded tokens
out_csv$ = replace$(in_csv$, ".csv", out_csv_suffix$ + ".csv", 1)
##Name of column for storing codes
code_col$ = "HandCode"
##Variants
variants$# = {"Full vowel", "Reduced"}
##Number of times to play token when it's loaded
autoplays = 1
##Buffer in seconds between multiple autoplays (if applicable)
autoplay_buffer = 0.25
##Randomize token order?
shuffle = 1
##Input column names
transcript_column$ = "Transcript"
utterance_start_time_column$ = "Line"
utterance_end_time_column$ = "LineEnd"
word_start_time_column$ = "word start"
word_end_time_column$ = "word end"
##Special codes
unsure_code$ = "(unsure)"
excluded_code$ = "(not a token)"

##Tracking variables
file_in_progress = 0
already_visited_advanced = 0

##Optional settings dialogs
while use_form
  if use_form = 1
    ##Basic settings
    ##Unparse variants vector to string
    variants$ = variants$#[1]
    for i from 2 to size(variants$#)
      variants$ = variants$ + "," + variants$#[i]
    endfor
    ##Form
    beginPause: "Token coding - basic settings"
      if not already_visited_advanced
        comment: "Search name is at the top of the Results page"
        text: 2, "Search name", search_name$
        comment: "Folder that contains files downloaded from APLS:"
        comment: "1. CSV file"
        comment: "2. Subfolder with TextGrid files"
        comment: "3. Subfolder with wav files"
        folder: "Input folder", in_dir$
      endif
      comment: "Check the box if you're picking up where you left off on a partially coded file"
      boolean: "File in progress", 0
      comment: "Column for storing codes (will be created if it doesn't exist)"
      sentence: "Code column", code_col$
      comment: "Variants (separated by commas)"
      comment: "Example: diphthong,monophthong,intermediate"
      sentence: "Variants", variants$
      comment: "Other settings"
      integer: "Number of autoplays", autoplays
      boolean: "Randomize token order", 1
      boolean: "Save output to csv file", 1
    clicked = endPause: "Continue", "Advanced settings", 1
    
    ##Translate/validate variables
    if search_name$ <> ""
      @search_name_to_filename: search_name$
      search_name$ = search_name_to_filename.search_name$
    else
      exitScript: "Search name must not be blank"
    endif
    if folderExists(input_folder$)
      in_dir$ = input_folder$
    else
      exitScript: "Input folder " + input_folder$ + " doesn't exist"
    endif
    if code_column$ <> ""
      code_col$ = code_column$
    else
      exitScript: "Code column must not be blank"
    endif
    if number_of_autoplays > 0
      autoplays = number_of_autoplays
    else
      autoplays = 0
    endif
    shuffle = randomize_token_order
    write = save_output_to_csv_file
    ##Defaults for advanced settings
    if not already_visited_advanced
      in_dir$ = replace_regex$(in_dir$, "/$", "", 1)
      tg_dir$ = in_dir$ + "/fragments_" + search_name$ + "/"
      wav_dir$ = in_dir$ + "/media_" + search_name$ + "/"
      in_csv$ = in_dir$ + "/" + "results_" + search_name$ + ".csv"
      if file_in_progress
        if not endsWith(in_csv$, out_csv_suffix$ + ".csv")
          in_csv$ = replace$(in_csv$, ".csv", out_csv_suffix$ + ".csv", 1)
        endif
        out_csv$ = in_csv$
      else
        out_csv$ = replace$(in_csv$, ".csv", out_csv_suffix$ + ".csv", 1)
      endif
    endif
    
    ##Parse variants string to vector
    num_variants = 1
    variants$ = replace_regex$(variants$, ",+", ",", 0)
    variants$ = replace_regex$(variants$, ",$", "", 1)
    while index(variants$, ",")
      v$[num_variants] = replace_regex$(variants$, ",.+", "", 1)
      variants$ = replace$(variants$, v$[num_variants] + ",", "", 1)
      num_variants = num_variants + 1
    endwhile
    v$[num_variants] = variants$
    if num_variants = 1
      exitScript: "Please specify 2 or more variants (separated with commas)"
    endif
    variants$# = empty$#(num_variants)
    for i from 1 to num_variants
      if v$[i] = unsure_code$
        exitScript: "This script uses """ + unsure_code$ + """ to mark unsure tokens." + newline$ + "Please rename the """ + unsure_code$ + """ variant to something else." + newline$
      endif
      if v$[i] = excluded_code$
        exitScript: "This script uses """ + excluded_code$ + """ to mark excluded tokens." + newline$ + "Please rename the """ + excluded_code$ + """ variant to something else." + newline$
      endif
      variants$#[i] = v$[i]
    endfor
    
    ##Determine next destination
    if clicked = 1
      use_form = 0
    else
      use_form = clicked
    endif
  elsif use_form = 2
    ##Advanced settings
    beginPause: "Token coding - advanced settings"
      comment: "File paths"
      infile: "Input csv file (downloaded from APLS)", in_csv$
      folder: "Folder that contains TextGrid files", tg_dir$
      folder: "Folder that contains wav files", wav_dir$
      if write
        outfile: "Output csv file (will be created if it doesn't exist)", out_csv$
      endif
      comment: "Input column names"
      sentence: "Transcript", transcript_column$
      sentence: "Utterance start time", utterance_start_time_column$
      sentence: "Utterance end time", utterance_end_time_column$
      sentence: "Word start time", word_start_time_column$
      sentence: "Word end time", word_end_time_column$
      if autoplays > 1
        comment: "Other settings"
        positive: "Time between autoplays", autoplay_buffer
      endif
    clicked = endPause: "Continue", "Basic settings", 1
    
    ##Validate/translate variables (validate paths below)
    in_csv$ = input_csv_file$
    tg_dir$ = replace_regex$(folder_that_contains_TextGrid_files$, "/$", "", 1)
    wav_dir$ = replace_regex$(folder_that_contains_wav_files$, "/$", "", 1)
    if write
      if output_csv_file$ = ""
        exitScript: "Output csv file must not be blank"
      elsif not endsWith_caseInsensitive(output_csv_file$, ".csv")
        out_csv$ = output_csv_file$ + ".csv"
      else
        out_csv$ = output_csv_file$
      endif
    endif
    if transcript$ <> ""
      transcript_column$ = transcript$
    else
      exitScript: "Transcript column must not be blank"
    endif
    if utterance_start_time$ <> ""
      utterance_start_time_column$ = utterance_start_time$
    else
      exitScript: "Utterance start time column must not be blank"
    endif
    if utterance_end_time$ <> ""
      utterance_end_time_column$ = utterance_end_time$
    else
      exitScript: "Utterance end time column must not be blank"
    endif
    if word_start_time$ <> ""
      word_start_time_column$ = word_start_time$
    else
      exitScript: "Word start time column must not be blank"
    endif
    if word_end_time$ <> ""
      word_end_time_column$ = word_end_time$
    else
      exitScript: "Word end time column must not be blank"
    endif
    if autoplays > 1
      autoplay_buffer = time_between_autoplays
    endif
    
    ##Determine next destination
    use_form = clicked - 1
    already_visited_advanced = 1
  endif
  
  ##Validate paths
  if not fileReadable(in_csv$)
    exitScript: "Input csv file " + in_csv$ + " doesn't exist"
  endif
  if not folderExists(tg_dir$)
    exitScript: "TextGrid folder " + tg_dir$ + " doesn't exist"
  endif
  if not folderExists(wav_dir$)
    exitScript: "Wav folder " + wav_dir$ + " doesn't exist"
  endif
endwhile

##Ask before overwriting out_csv$
if write and fileReadable(out_csv$)
  beginPause: "Overwrite output file?"
    comment: "Output csv file already exists:"
    comment: out_csv$
    comment: ""
    comment: "Continue and overwrite it?"
  clicked = endPause: "Yes", "No", 2
  if clicked = 2
    beginPause: "Bye!"
      comment: "Bye!"
    endPause: "OK", 1, 1
    exitScript()
  endif
endif

##Set up data
table = Read Table from comma-separated file: in_csv$
num_tokens = Get number of rows
has_code_column = Get column index: code_col$
##Handle different possible data states
if not has_code_column
  Append column: code_col$
  tokens_to_code# = to#(num_tokens)
else
  ##If code_col$ already exists and has entries, ask if the user wants to code all tokens (supply defaults for file_in_progress)
  blank# = List row numbers where... self$[row, code_col$] = ""
  coded# = List row numbers where... self$[row, code_col$] <> "" and self$[row, code_col$] <> unsure_code$ and self$[row, code_col$] <> excluded_code$
  unsure# = List row numbers where... self$[row, code_col$] = unsure_code$
  excluded# = List row numbers where... self$[row, code_col$] = excluded_code$
  num_blank = size(blank#)
  num_coded = size(coded#)
  num_unsure = size(unsure#)
  num_excluded = size(excluded#)
  ##Defaults
  code_uncoded_tokens = 1
  recode_coded_tokens = 0
  recode_unsure_tokens = 0
  recheck_excluded_tokens = 0
  if num_blank = num_tokens
    tokens_to_code# = to#(num_tokens)
  else
    ##Supply defaults for file_in_progress
    if not file_in_progress
      beginPause: "Select tokens to code"
        comment: "Currently, the " + code_col$ + " column has:"
        comment: "Uncoded tokens: " + string$(num_blank)
        comment: "Coded tokens: " + string$(num_coded)
        comment: "'Unsure' tokens: " + string$(num_unsure)
        comment: "Excluded tokens: " + string$(num_excluded)
        comment: ""
        comment: "Which tokens would you like to code?"
        if num_blank > 0
          boolean: "Code uncoded tokens", code_uncoded_tokens
        endif
        if num_coded > 0
          boolean: "Recode coded tokens", recode_coded_tokens
        endif
        if num_unsure > 0
          boolean: "Recode unsure tokens", recode_unsure_tokens
        endif
        if num_excluded > 0
          boolean: "Recheck excluded tokens", recheck_excluded_tokens
        endif
      endPause: "Continue", 1
    endif
    
    ##Construct tokens_to_code#
    tokens_to_code# = zero#(0)
    if code_uncoded_tokens
      tokens_to_code# = combine#(tokens_to_code#, blank#)
    endif
    if recode_coded_tokens
      tokens_to_code# = combine#(tokens_to_code#, coded#)
    endif
    if recode_unsure_tokens
      tokens_to_code# = combine#(tokens_to_code#, unsure#)
    endif
    if recheck_excluded_tokens
      tokens_to_code# = combine#(tokens_to_code#, excluded#)
    endif
    if size(tokens_to_code#) = 0
      beginPause: "Bye!"
        comment: "No tokens selected. Bye!"
      endPause: "OK", 1, 1
      exitScript()
    endif
  endif
endif
##Optionally shuffle
if shuffle
  random_initializeWithSeedUnsafelyButPredictably(1234)
  tokens_to_code# = shuffle#(tokens_to_code#)
endif

##Loop over tokens and code
i = 0
repeat
  ##Iterate
  i = i + 1
  
  ##Get data from table
  token = tokens_to_code#[i]
  selectObject: table
  transcript$ = Get value: token, transcript_column$
  line_start = Get value: token, utterance_start_time_column$
  line_end = Get value: token, utterance_end_time_column$
  word_start = Get value: token, word_start_time_column$
  word_end = Get value: token, word_end_time_column$
  
  ##Open in editor
  file_stem$ = replace$(transcript$, ".eaf", "", 1) + "__" + fixed$(line_start, 3) + "-" + fixed$(line_end, 3)
  sound = Read from file: wav_dir$ + "/" + file_stem$ + ".wav"
  tg = Read from file: tg_dir$ + "/" + file_stem$ + ".TextGrid"
  selectObject: sound, tg
  View & Edit
  editor: tg
    Select: word_start - line_start, word_end - line_start
    Zoom to selection
    Zoom out
    for ap from 1 to autoplays
      Play window
      if ap < autoplays
        sleep(autoplay_buffer)
      endif
    endfor
    still_deciding = 1
    while still_deciding
      beginPause: "Code this token"
        choice: "Code", 1
        for v from 1 to size(variants$#)
          option: variants$#[v]
        endfor
      clicked = endPause: "Code", "Unsure", "Exclude", "Replay", if write then "Save & exit" else "Exit" fi, 1, 5
      still_deciding = 0
      if clicked = 2
        code$ = unsure_code$
      elsif clicked = 3
        code$ = excluded_code$
      elsif clicked = 4
        still_deciding = 1
        Play window
      elsif clicked = 5
        code$ = ""
        i = size(tokens_to_code#)
      endif
    endwhile
  endeditor
  
  ##Write to table
  selectObject: table
  Set string value: token, code_col$, code$
  
  ##Clean up
  removeObject: sound, tg
until i = size(tokens_to_code#)

##Optionally write to output csv file
if write
  selectObject: table
  Save as comma-separated file: out_csv$
  beginPause: "All done!"
    comment: "All done!"
    comment: ""
    comment: "Coding file saved as"
    comment: out_csv$
  endPause: "OK", 1, 1
else
  beginPause: "All done!"
    comment: "All done!"
    comment: ""
    comment: "To save your coding file..."
    comment: "1. In the next window, click 'Save'"
    comment: "2. Click 'Save as comma-separated file...'"
    comment: "3. Choose a file location and name"
  endPause: "OK", 1, 1
endif

##Convert search names to filenames
##https://nzilbb.github.io/ag/apidocs/nzilbb/util/IO.html#SafeFileNameUrl(java.lang.String)
procedure search_name_to_filename: .search_name$
  .search_name$ = replace_regex$(.search_name$, "[\\?*+$]", "", 0)
  .search_name$ = replace$(.search_name$, "<=", "-le-", 0)
  .search_name$ = replace$(.search_name$, "<", "-lt-", 0)
  .search_name$ = replace$(.search_name$, ">=", "-ge-", 0)
  .search_name$ = replace$(.search_name$, ">", "-gt-", 0)
  .search_name$ = replace_regex$(.search_name$, "[|:!=^]", "_", 0)
  .search_name$ = replace$(.search_name$, ",", "-", 0)
  .search_name$ = replace$(.search_name$, "@", "-at-", 0)
  .search_name$ = replace$(.search_name$, "&", "-amp-", 0)
  .search_name$ = replace_regex$(.search_name$, "^\.", "_.", 0)
  .search_name$ = replace_regex$(.search_name$, "\.$", "._", 0)
  .search_name$ = replace$(.search_name$, newline$, "", 0)
endproc

#### End of main script

##Plugin: ParseValidateVersion.praat
##https://github.com/djvill/hwttiwtot/blob/abd33fa/Praat/ParseValidateVersion.praat
procedure parseVersion: .v$
  ##Ensure version string is correctly formatted
  versionRE$ = "^\d+\.\d+(\.\d+)?$"
  if not index_regex(.v$, versionRE$)
    exitScript: "Error in @parseVersion: Incorrect format for version string (", .v$, ")."
  endif
  
  ##Parse version string
	.major = number(replace_regex$(.v$, "\..+", "", 0))
	dot1 = index(.v$, ".")
	dot2 = rindex(.v$, ".")
	if dot1 = dot2
		.minor = number(replace_regex$(.v$, ".+\.", "", 0))
		.patch = 0
	else
		noMajor$ = replace_regex$(.v$, "^.+?\.", "", 0)
		.minor = number(replace_regex$(noMajor$, "\..+", "", 0))
		.patch = number(replace_regex$(.v$, ".+\.", "", 0))
	endif
endproc

procedure validateVersion: .minVersion$
  ##Parse current and minimum versions
	@parseVersion: praatVersion$
	currMajor = parseVersion.major
	currMinor = parseVersion.minor
	currPatch = parseVersion.patch
	@parseVersion: .minVersion$
	minMajor = parseVersion.major
	minMinor = parseVersion.minor
	minPatch = parseVersion.patch
  
  ##Construct exit message
  newlineIndent$ = newline$ + replace_regex$("Error: ", ".", " ", 0)
  exitMsg$ = "This script requires Praat to be at least version " + .minVersion$ + newlineIndent$ + "You have version " + praatVersion$ + newlineIndent$ + "Please download a more recent version of Praat:" + newlineIndent$ + "https://www.fon.hum.uva.nl/praat/"
  
  ##Compare current to minimum
  if currMajor < minMajor
    exitScript: exitMsg$
  elsif currMajor = minMajor
    if currMinor < minMinor
      exitScript: exitMsg$
    elsif currMinor = minMinor
      if currPatch < minPatch
        exitScript: exitMsg$
      endif
    endif
  endif
endproc
