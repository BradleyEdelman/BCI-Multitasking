function str = c_str_toTitleCase(str)
assert(ischar(str));
str = strtrim(str);
indicesToUpper = isspace(str);
indicesToUpper = [true indicesToUpper(1:end-1)];
str(indicesToUpper) = upper(str(indicesToUpper));
end