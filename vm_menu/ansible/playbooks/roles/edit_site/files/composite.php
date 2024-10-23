#!/usr/bin/php
<?php
$options = getopt("f:");

if (!isset($options["f"]) || strlen($options["f"]) < 1 || !file_exists($options["f"]))
{
    fputs(STDERR, "File Not Found\n");
    exit(1);
}

$arHTMLPagesOptions = array();
include($options["f"]);

// Remove single quotes from mask patterns
if (isset($arHTMLPagesOptions['~INCLUDE_MASK']) && is_array($arHTMLPagesOptions['~INCLUDE_MASK'])) {
    $arHTMLPagesOptions['~INCLUDE_MASK'] = array_map(function($item) {
        return trim($item, "'");
    }, $arHTMLPagesOptions['~INCLUDE_MASK']);
}

if (isset($arHTMLPagesOptions['~EXCLUDE_MASK']) && is_array($arHTMLPagesOptions['~EXCLUDE_MASK'])) {
    $arHTMLPagesOptions['~EXCLUDE_MASK'] = array_map(function($item) {
        return trim($item, "'");
    }, $arHTMLPagesOptions['~EXCLUDE_MASK']);
}

fputs(STDOUT, json_encode($arHTMLPagesOptions));
exit(0);
?>
