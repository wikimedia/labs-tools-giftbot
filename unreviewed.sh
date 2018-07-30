cd PHPWikiBot

for config in antik aus egypt bawue berg bghsw bio bos chem computerspiel country dortmund ehock esc foot frei grue hockey info kanu laus linux marx math mhess motor muensterland musik myth norwegen owl phil phys pol religion rheinneckar sachs sauer schuldrecht schweiz segeln soft sozi spam stat street tennis tv umwelt wirt wsport
do
	echo unreviewed-$config:
	./PHPWikiBot.php login unreviewed config=unreviewed-$config
done
