const express = require('express');
const mongoose = require('mongoose');
const axios = require('axios');
const cheerio = require('cheerio');
const puppeteer = require('puppeteer');

const app = express();
const PORT = 5000;

// Configuration MongoDB
mongoose.connect('mongodb://127.0.0.1:27017/exchangeRates', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});
const rateSchema = new mongoose.Schema({
    site: String,
    rate: String,
    timestamp: { type: Date, default: Date.now },
});
const Rate = mongoose.model('Rate', rateSchema);

// Fonction de scraping pour Gandyam Pay
async function scrapeGandyamPay() {
    const url = 'https://gandyampay.com';
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();

    try {
        await page.goto(url, { waitUntil: 'networkidle2' });

        // Évaluer le DOM pour récupérer le taux
        const rate = await page.evaluate(() => {
            const rateContainer = document.querySelector(
                'div[style="display: flex; justify-content: space-between; align-items: center;"]'
            );
            if (!rateContainer) return null;

            // Récupérer les enfants <p> de ce conteneur
            const rateValues = rateContainer.querySelectorAll('p');
            if (rateValues.length >= 2) {
                // Le taux semble être dans le 2ème <p>
                return rateValues[1].innerText.trim();
            }
            return null;
        });

        if (!rate) {
            throw new Error('Taux non trouvé sur Gandyam Pay.');
        }

        return { site: 'Gandyam Pay', rate };
    } catch (error) {
        console.error('Erreur lors du scraping de Gandyam Pay:', error.message);
        return null;
    } finally {
        await browser.close();
    }
}


// Fonction de scraping pour Ria Money Transfer
async function scrapeRiaMoneyTransfer() {
    const url = 'https://www.riamoneytransfer.com/fr-fr'; // URL du site
    try {
        const { data } = await axios.get(url);
        const $ = cheerio.load(data);
        const input = $('input[placeholder="0"]');
        const rate = input.val(); // Récupère la valeur actuelle
        return { site: 'Ria Money Transfer', rate };
    } catch (error) {
        console.error('Erreur lors du scraping de Ria Money Transfer:', error);
        return null;
    }
}

// Route GET : Récupérer les taux stockés
app.get('/taux', async (req, res) => {
    try {
        const rates = await Rate.find();
        res.json(rates);
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la récupération des taux.' });
    }
});

// Route POST : Rafraîchir les taux
app.post('/taux/refresh', async (req, res) => {
    try {
        const gandyamRate = await scrapeGandyamPay();
        const riaRate = await scrapeRiaMoneyTransfer();

        if (gandyamRate) {
            await Rate.findOneAndUpdate(
                { site: gandyamRate.site },
                gandyamRate,
                { upsert: true, new: true }
            );
        }
        if (riaRate) {
            await Rate.findOneAndUpdate(
                { site: riaRate.site },
                riaRate,
                { upsert: true, new: true }
            );
        }

        res.json({ message: 'Taux mis à jour avec succès.' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la mise à jour des taux.' });
    }
});

// Démarrage du serveur
app.listen(PORT, () => {
    console.log(`Serveur en cours d'exécution sur http://localhost:${PORT}`);
});
