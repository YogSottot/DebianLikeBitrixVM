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
