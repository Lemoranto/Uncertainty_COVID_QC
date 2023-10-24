import os
from webdriver_manager.chrome import ChromeDriverManager
from time import sleep
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import time
from selenium.common.exceptions import NoSuchElementException

def get_conference_links(soup):
    conferences = []
    for tr in soup.find_all("tr", {"data-type": "ConferencePointPresse"}):
        a = tr.find("a", href=True)
        if a:
            link = "https://assnat.qc.ca" + a["href"]
            description = tr.find("td", class_="gauche").text.lower()
            if "conférence de presse" in description and "ministre" in description and "covid" not in description:
                date = tr.find("div", class_="date").text.strip()
                conferences.append((link, date))
    return conferences

def is_next_page_visible(driver):
    try:
        next_page_link = driver.find_element(By.XPATH, '//div[@class="pagesPrecises"]/a[not(@class="courant") and not(contains(@style, "display: none;"))]')
        return next_page_link is not None
    except:
        return False

def navigate_to_next_page(driver):
    current_page_number = int(driver.find_element(By.CSS_SELECTOR, ".pageCourante").text)
    next_page_number = current_page_number + 1

    try:
        next_page_link = driver.find_element(By.XPATH, f'//div[@class="pagesPrecises"]/a[@data-num-page="{next_page_number - 1}"]')
        next_page_link.click()
    except NoSuchElementException:
        print("No more pages to visit.")
        return False

    return True


base_url = "https://assnat.qc.ca/fr/actualites-salle-presse/conferences-points-presse/index.html"
output_folder = "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/AutoTranscribeAndScrape/recup_transcriptions/extracted_transcriptions/conf_covid_full/conf_not_covid"
os.makedirs(output_folder, exist_ok=True)

options = webdriver.ChromeOptions()
driver = webdriver.Chrome(executable_path=ChromeDriverManager().install(), options=options)
driver.get(base_url)

# Entrer 'covid' dans "Mots clés"
keywords_input = driver.find_element(By.ID, "ctl00_ColGauche_RechercheActualitesSallePresse_txtMotsCles")
keywords_input.send_keys("covid")

# Laisser le temps à la page de charger
sleep(3)

# Sélectionner "Conférences et points de presse" dans "Type d'actualités"
news_type_selector = driver.find_element(By.ID, "ctl00_ColGauche_RechercheActualitesSallePresse_ddlChoixTypeActualite")
news_type_selector.send_keys("Conférences et points de presse")

# Laisser le temps à la page de charger
sleep(3)

# Sélectionner les périodes

start_date_input = driver.find_element(By.NAME, "ctl00$ColGauche$RechercheActualitesSallePresse$txtDateDebut")
start_date_input.click()
time.sleep(1)
for char in "2020-01-01":
    start_date_input.send_keys(char)
    time.sleep(1)

end_date_input = driver.find_element(By.NAME, "ctl00$ColGauche$RechercheActualitesSallePresse$txtDateFin")
end_date_input.click()
time.sleep(1)
for char in "2023-05-01":
    end_date_input.send_keys(char)
    time.sleep(1)


# Laisser le temps à la page de charger
sleep(3)

# Cliquer sur le bouton "Rechercher"
search_button = driver.find_element(By.CSS_SELECTOR, ".btnRechercheContextuelle > .btnSoumettre")
search_button.click()

# Laisser le temps à la page de charger
sleep(3)

# Changer le nombre de résultats par page à 100
results_per_page_selector = driver.find_element(By.CSS_SELECTOR, ".quantiteParPage")
results_per_page_selector.send_keys("100")

# Laisser le temps à la page de charger
sleep(3)

# Récupérer le nombre total de pages
soup = BeautifulSoup(driver.page_source, "html.parser")
# Initialiser la liste des liens et informations des conférences
all_conference_links = []

# Extraire les liens des conférences et les informations de la première page
conference_links = get_conference_links(soup)
all_conference_links.extend(conference_links)

# Parcourir les pages suivantes et extraire les liens et les informations des conférences
while True:
    sleep(3)
    
    soup = BeautifulSoup(driver.page_source, "html.parser")
    conference_links = get_conference_links(soup)
    all_conference_links.extend(conference_links)

    if not navigate_to_next_page(driver):
        break

# Parcourir toutes les conférences récupérées
for conference_link, date in all_conference_links:
    driver.get(conference_link)
    sleep(2)

    # Récupérer et formater la date
    day, month, year = date.split()
    day = day.zfill(2)
    month = month.lower()
    month = {"janvier": "01", "février": "02", "mars": "03", "avril": "04", "mai": "05", "juin": "06",
             "juillet": "07", "août": "08", "septembre": "09", "octobre": "10", "novembre": "11",
             "décembre": "12"}[month]
    year = year.strip()


    # Accéder à la page de la transcription
    print(f"Conference link: {conference_link}")

    # Laisser le temps à la page de charger
    sleep(2)

    # Extraire le texte de la transcription
    transcription_title = "Titre et participants : " +driver.find_element(By.CSS_SELECTOR, ".colonneImbriquee.imbGauche > h1").text.strip()+ "."
    transcription_subtitle = "Sujet : " + driver.find_element(By.CSS_SELECTOR, ".colonneImbriquee.imbGauche > h2").text.strip() + "."
    transcription_date_time = driver.find_elements(By.CSS_SELECTOR, ".colonneImbriquee.imbGauche > h3")
    transcription_date = "Date : " + transcription_date_time[0].text.strip()+ "."
    transcription_time = "Lieu : " + transcription_date_time[1].text.strip()+ "."
    transcription_text = "Début de la transcription : " + driver.find_element(By.CSS_SELECTOR, ".colonneImbriquee.imbGauche > div").text.strip() + "Fin de la transcription"


    # Enregistrer la transcription au format .txt
    output_filename = f"Transcription_{year}_{month}_{day}.txt"
    output_path = os.path.join(output_folder, output_filename)
    with open(output_path, "w", encoding="utf-8") as output_file:
        output_file.write(transcription_title + "\n")
        output_file.write(transcription_subtitle + "\n")
        output_file.write(transcription_date + "\n")
        output_file.write(transcription_time + "\n")
        output_file.write(transcription_text)

    print(f"Transcription sauvegardée: {output_filename}")

driver.quit()
