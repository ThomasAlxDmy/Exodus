## v1.1.4

* Added rake task: rake db:reset

## v1.1.3

* Small changes around rerunnable migrations

## v1.1.2

* Exodus now supports custom namespacing to not conflict with AR db:migrate

## v1.1.1

* Extracted methods from the rake file itself into a module
* Fixed running custom migrations

## v1.1.0

* Changed the way migration are executed 
* Cleaner output
* Ability to see which migration will be executed before rake db:migrate and db:rollback with rake db:migrate:show and db:rollback:show
* Fixed a text formatter issue

## v1.0.6

* Text formatter bug fix

## v1.0.5

* Added helpers folder + module to do cleaner and prettier prints

## v1.0.4

* Custom migrations now run in the given order

## v1.0.3

* Bug fix -- rake needs to be required in exodus.rake

## v1.0.2

* Gem can now been included in any ruby project

## v1.0.1

* Small refactoring

## v1.0.0

* Initial release