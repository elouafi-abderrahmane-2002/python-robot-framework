*** Settings ***
Library    SeleniumLibrary
Library    LambdaTestStatus.py

*** Variables ***

${BROWSER}          ${ROBOT_BROWSER}
${REMOTE_URL}       http://%{LT_USERNAME}:%{LT_ACCESS_KEY}@hub.lambdatest.com/wd/hub
${TIMEOUT}          3000

# LambdaTest Capabilities
&{LT_OPTIONS}
...    browserName=${browserName}
...    platformName=${platform}
...    browserVersion=${version}
...    visual=${visual}
...    network=${network}
...    console=${console}
...    name=RobotFramework Lambda Test

*** Keywords ***

Open test browser
    [Timeout]    ${TIMEOUT}
    # Create Selenium options based on browser
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].${BROWSER.capitalize()}Options()    sys, selenium.webdriver
    Call Method    ${options}    set_capability    LT:Options    ${LT_OPTIONS}
    Open Browser   https://lambdatest.github.io/sample-todo-app/    ${BROWSER}    remote_url=${REMOTE_URL}    options=${options}

Close test browser
    Run Keyword If    '${REMOTE_URL}' != ''
    ...    Report Lambdatest Status    ${TEST_NAME}    ${TEST_STATUS}
    Close All Browsers