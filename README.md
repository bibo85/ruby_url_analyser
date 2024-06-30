# Анализатор urls адресов
Скрипт получает на вход список адресов url из файла и выводит в консоль статистику по средней скорости загрузке страниц
и размеру полученного контента в килобайтах.

![Static Badge](https://img.shields.io/badge/ruby%20-%203.0.6p216%20-red)


## Настройка
Перед запуском необходимо сделать файл [url_analyser.rb](url_analyser.rb) исполняемым, запустив в терминале 
команду:

```console
$ chmod +x url_analyser.rb
```

## Справка
Для получения справки введите команду -h или --help

```console
$ ./url_analyser.rb --help
```

## Доступные аргументы
```console
Usage: url_analyser.rb [options]
-a, --attempts [INTEGER]         Необязательный аргумент. Количество попыток для опроса url (по умолчанию 10)
-f, --file STRING                Обязательный аргумент. Путь к файлу. Абсолютный или относительный
```

## Запуск

- Вызов скрипт с явным указанием количества попыток
```console
$ ./url_analyser.rb --attempts=20 --file=urls.txt 
```

- Вызов скрипт без указания количества попыток. 

  В этом случае количество попыток устанавливается по умолчанию - 10

```console
$ ./url_analyser.rb --file=urls.txt 
```

## Пример вывода результата
```console
foo - invalid url
https://www.site5.com - Не удается получить доступ к сайту. Проверьте корректность адреса
https://www.yandex.ru/foo - 404

A-rating:

https://www.site1.com - 0.55sec - 10kb
https://www.site2.com - 0.44sec - 20kb
https://www.site3.com - 0.78sec - 100kb

B-rating:

...

F-rating

https://www.site4.com - 503
https://www.site5.com - 502
```
