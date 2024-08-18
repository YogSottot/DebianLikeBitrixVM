fix select edition in non-ru browser

```
<?if ($isCrm || LANG != 'ru'):?>
```
to
```
<?if ($isCrm):?>
```
```
		$langs = array('en','de');
							if (LANG == 'ru')
							{
								$langs = array('en','de','ru');
							}
								
							foreach ($langs as $l)
```
to
```
foreach(array('en','de','ru') as $l)
```

```
#!/bin/bash

# Change the first occurrence
sed -i '0,/<?if ($isCrm || LANG != '\''ru'\''):?>/s//<?if ($isCrm):?>/' bitrixsetup.php

# Change the foreach loop
sed -i '/\$langs = array/,/foreach (\$langs as \$l)/c\							foreach(array('\''en'\'','\''de'\'','\''ru'\'') as $l)' bitrixsetup.php

echo "Changes applied successfully."
```

```
- name: Update bitrixsetup.php file
  replace:
    path: /path/to/bitrixsetup.php
    regexp: '{{ item.regexp }}'
    replace: '{{ item.replace }}'
  loop:
    - { regexp: '<\?if \(\$isCrm \|\| LANG != ''ru''\):\?>', replace: '<?if ($isCrm):?>' }
    - { regexp: '\$langs = array.*\n.*\n.*foreach \(\$langs as \$l\)', replace: '							foreach(array(''en'',''de'',''ru'') as $l)' }


```
