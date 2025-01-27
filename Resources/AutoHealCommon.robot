*** Settings ***
Library    SeleniumLibrary
Library    LambdaTestStatus.py

*** Variables ***

${BROWSER}          ${ROBOT_BROWSER}
${REMOTE_URL}       https://%{LT_USERNAME}:%{LT_ACCESS_KEY}@hub.lambdatest.com/wd/hub
${TIMEOUT}          3000
${AUTOHEAL_URL}     https://www.lambdatest.com/selenium-playground/auto-healing

# LambdaTest Capabilities with AutoHeal enabled
&{LT_OPTIONS_AUTOHEAL_TRUE}
...    browserName=${browserName}
...    platformName=${platform}
...    browserVersion=${version}
...    visual=${True}
...    network=${True}
...    console=${True}
...    autoHeal=${True}
...    name=RobotFramework AutoHeal Demo

*** Keywords ***

Open AutoHeal Browser With AutoHeal Enabled
    [Arguments]    ${test_name}=RobotFramework AutoHeal Demo
    [Timeout]    ${TIMEOUT}
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].${BROWSER.capitalize()}Options()    sys, selenium.webdriver
    ${lt_options}=    Create Dictionary    
    ...    browserName=${browserName}
    ...    platformName=${platform}
    ...    browserVersion=${version}
    ...    visual=${True}
    ...    network=${True}
    ...    console=${True}
    ...    autoHeal=${True}
    ...    build=Demonstration of the AutoHeal - Robot Framework
    ...    name=${test_name}
    Call Method    ${options}    set_capability    LT:Options    ${lt_options}
    Open Browser    ${AUTOHEAL_URL}    ${BROWSER}    remote_url=${REMOTE_URL}    options=${options}
    Sleep    5s    Wait for page to fully load

Execute Step Context
    [Arguments]    ${message}    ${level}=info
    ${script}=    Set Variable    lambdatest_executor: {"action": "stepcontext", "arguments": {"data": "${message}", "level": "${level}"}}
    Execute Javascript    ${script}

Click Change DOM ID Button
    Click Element    xpath=//*[contains(text(), 'Change DOM ID')]

Fill Login Form
    [Arguments]    ${username}=test@gmail.com    ${password}=password
    # Using placeholder-based selectors as fallback since IDs may vary
    ${username_field}=    Set Variable    xpath=//input[@id='username' or @placeholder='Username*' or contains(@name, 'username')]
    ${password_field}=    Set Variable    xpath=//input[@id='password' or @placeholder='Password*' or contains(@name, 'password') or @type='password']
    Input Text    ${username_field}    ${username}
    Input Text    ${password_field}    ${password}

Click Submit Button
    Click Element    xpath=//*[contains(text(), 'Submit')]

Close AutoHeal Browser
    Run Keyword If    '${REMOTE_URL}' != ''
    ...    Report Lambdatest Status    ${TEST_NAME}    ${TEST_STATUS}
    Close All Browsers

