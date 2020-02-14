# Slipway-test

The entire purpose of this repository is to be an example of a very minimal Hello World node app to test Slipway deploy mechanisms.

To try Slipway, first clone this project. Then clone the slipway project inside this project's root directory.

To set up staging and deploy currently checked out branch, run `./infra/init.sh staging`. 
Important: you must be in the repository's root folder. Do not cd to infra and run deploy.sh, this won't work.

To deploy some other branch, run  `./infra/init.sh staging some-branch`

To deploy master to production, run  `./infra/init.sh production master`.
