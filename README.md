# 🚀 Python + Robot Framework + CI/CD — Pipeline de Tests Automatisés

Un test automatisé qui ne tourne qu'en local, c'est insuffisant.
Ce projet met en place un pipeline complet : Robot Framework + Python,
exécution parallèle multi-navigateurs, et publication automatique des rapports
via GitHub Actions à chaque push ou pull request.

---

## Architecture du pipeline

```
  Push / Pull Request sur GitHub
          │
          ▼
  ┌───────────────────────────────────────────────────────────┐
  │                  GitHub Actions                           │
  │                                                           │
  │  Job 1         Job 2          Job 3          Job 4        │
  │  Chrome        Firefox        Edge           Headless     │
  │  (ubuntu)      (ubuntu)       (windows)      (ubuntu)     │
  │                                                           │
  │  ┌──────────────────────────────────────────────────────┐ │
  │  │   robot --variable BROWSER:${BROWSER} tests/         │ │
  │  └──────────────────────────────────────────────────────┘ │
  │                        │                                  │
  │                        ▼                                  │
  │              rebot --merge results/     ← merge résultats │
  │                        │                                  │
  │                        ▼                                  │
  │              report.html publié en artifact               │
  └───────────────────────────────────────────────────────────┘
```

---

## Structure du projet

```
  python-robot-framework-ci/
  │
  ├── tests/
  │   ├── login_tests.robot         ← tests d'authentification
  │   ├── navigation_tests.robot    ← tests de navigation
  │   ├── form_tests.robot          ← tests de formulaires
  │   └── regression_suite.robot    ← suite de non-régression
  │
  ├── resources/
  │   ├── keywords.robot            ← mots-clés partagés
  │   ├── variables.robot           ← variables de configuration
  │   └── page_objects/             ← Page Object Model
  │       ├── login_page.robot
  │       └── dashboard_page.robot
  │
  ├── test_data/
  │   ├── valid_users.csv           ← données de test externes
  │   └── invalid_credentials.csv
  │
  └── .github/workflows/
      └── robot-ci.yml
```

---

## Tests avec Page Object Model

```robotframework
*** Settings ***
Resource    ../resources/page_objects/login_page.robot
Resource    ../resources/page_objects/dashboard_page.robot
Library     SeleniumLibrary

Suite Setup     Open Browser Session
Suite Teardown  Close Browser Session

*** Test Cases ***

TC-001 : Connexion avec identifiants valides
    [Tags]    smoke    regression
    Login Page.Navigate To Login
    Login Page.Enter Username    ${VALID_USER}
    Login Page.Enter Password    ${VALID_PASS}
    Login Page.Submit Login Form
    Dashboard Page.Should Be On Dashboard
    Dashboard Page.Username Should Be    ${VALID_USER}

TC-002 : Connexion avec mot de passe incorrect
    [Tags]    regression    negative
    Login Page.Navigate To Login
    Login Page.Enter Username    ${VALID_USER}
    Login Page.Enter Password    wrong_password
    Login Page.Submit Login Form
    Login Page.Error Message Should Be    Identifiants incorrects

TC-003 : Connexion data-driven
    [Tags]    regression
    [Template]    Verify Login Scenario
    valid_user      correct_pass      success
    unknown_user    any_pass          user_not_found
    valid_user      wrong_pass        invalid_password
    locked_user     correct_pass      account_locked
```

---

## GitHub Actions — exécution parallèle multi-navigateurs

```yaml
# .github/workflows/robot-ci.yml
name: Robot Framework CI

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        browser: [chrome, firefox, edge]
        os: [ubuntu-latest, windows-latest]
        exclude:
          - os: ubuntu-latest
            browser: edge   # Edge non disponible sur Ubuntu

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Robot Framework & libraries
        run: |
          pip install robotframework
          pip install robotframework-seleniumlibrary
          pip install webdrivermanager
          webdrivermanager ${{ matrix.browser }}

      - name: Run tests on ${{ matrix.browser }}
        run: |
          robot \
            --variable BROWSER:${{ matrix.browser }} \
            --outputdir results/${{ matrix.browser }} \
            --loglevel INFO \
            --tagstatinclude smoke \
            --tagstatinclude regression \
            tests/

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: results-${{ matrix.browser }}-${{ matrix.os }}
          path: results/${{ matrix.browser }}/

  merge-results:
    needs: test
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Download all results
        uses: actions/download-artifact@v4
        with:
          path: all-results/

      - name: Merge Robot Framework reports
        run: |
          pip install robotframework
          rebot --merge --outputdir merged-results all-results/**/output.xml

      - name: Publish merged report
        uses: actions/upload-artifact@v4
        with:
          name: merged-test-report
          path: merged-results/
```

---

## Rapport d'anomalie — template documenté

```
BUG-042
─────────────────────────────────────────────────────────
Titre       : Le bouton Soumettre reste actif si le champ email est vide
Module      : Formulaire de contact
Sévérité    : MAJEURE  |  Priorité : HAUTE
Environnement : Chrome 120, Windows 10, v2.3.1

Étapes de reproduction :
  1. Accéder à /contact
  2. Laisser le champ "Email" vide
  3. Remplir les autres champs
  4. Cliquer sur "Soumettre"

Résultat obtenu   : La soumission est envoyée sans email
Résultat attendu  : Message "Email obligatoire" affiché, soumission bloquée
Test automatisé   : TC-FORM-007 (regression_suite.robot, ligne 42)
─────────────────────────────────────────────────────────
Statut : OUVERT → Assigné à : Dev Team → Sprint : 2024-S03
```

---

## Ce que j'ai appris

Le **Page Object Model** en Robot Framework change vraiment la maintenabilité.
Sans POM, si l'URL ou le locator d'un élément change, il faut mettre à jour
chaque test qui le référence. Avec POM, on modifie un seul endroit dans le
fichier de la page — tous les tests qui l'utilisent sont corrigés d'un coup.

L'exécution parallèle par navigateur via GitHub Actions a aussi révélé des
bugs intermittents qui ne se montraient qu'en conditions CI (chargement plus
lent, race conditions). Ces bugs n'auraient jamais été détectés en testant
uniquement en local sur Chrome.

---

*Projet réalisé dans le cadre de ma formation ingénieur — ENSET Mohammedia*
*Par **Abderrahmane Elouafi** · [LinkedIn](https://www.linkedin.com/in/abderrahmane-elouafi-43226736b/) · [Portfolio](https://my-first-porfolio-six.vercel.app/)*
