#!/usr/bin/env php
<?php

## From Behat Code

$gherkinUrl = 'https://raw.githubusercontent.com/cucumber/cucumber/master/gherkin/gherkin-languages.json';
$json  = file_get_contents($gherkinUrl);
$array = array();

foreach (json_decode($json, true) as $lang => $keywords) {
    $langMessages = array();

    foreach ($keywords as $type => $words) {
        if (!is_array($words)) {
            $words = array($words);
        }

        if ('scenarioOutline' === $type) {
            $type = 'scenario_outline';
        }

        if (in_array($type, array('given', 'when', 'then', 'and', 'but'))) {
            $formattedKeywords = array();

            foreach ($words as $word) {
                $formattedWord = trim($word);

                if ($formattedWord === $word) {
                    $formattedWord = $formattedWord.'<'; // Convert the keywords to the syntax used by Gherkin 2, which is expected by our Lexer.
                }

                $formattedKeywords[] = $formattedWord;
            }

            $words = $formattedKeywords;
        }

        usort($words, function($type1, $type2) {
            return mb_strlen($type2, 'utf8') - mb_strlen($type1, 'utf8');
        });

        $langMessages[$type] = implode('|', $words);
    }

    // ensure that the order of keys is consistent between updates
    ksort($langMessages);

    $array[$lang] = $langMessages;
}

// ensure that the languages are sorted to avoid useless diffs between updates. We keep the English first though as it is the reference.
$enData = $array['en'];
unset($array['en']);
ksort($array);
$array = array_merge(array('en' => $enData), $array);
$arrayString = var_export($array, true);

file_put_contents(__DIR__.'/../i18n.php', <<<EOD
<?php

/*
 * DO NOT TOUCH THIS FILE!
 *
 * This file is automatically generated by `bin/update_i18n`.
 * Actual Gherkin translations live in cucumber/gherkin repo:
 * {$gherkinUrl}
 * Please send your translation changes there.
 */

return $arrayString;
EOD
);
