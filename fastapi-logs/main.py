from fastapi import FastAPI
from google.cloud import firestore
import os
from dotenv import load_dotenv
from fastapi.responses import HTMLResponse

load_dotenv()
app = FastAPI()

@app.get("/", response_class=HTMLResponse)
async def index():
    db = firestore.Client()
    logs_ref = db.collection('logs').where('type', '==', 'feature_usage')
    docs = logs_ref.stream()
    
    counts = {}
    for doc in docs:
        data = doc.to_dict()
        feature = data.get('feature')
        if feature.startswith('search'):
            feature = 'search_*'
        counts[feature] = counts.get(feature, 0) + 1

    labels = list(counts.keys())
    values = list(counts.values())

    html = """
    <html>
    <head>
        <title>Dashboard</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    </head>
    <body>
        <h1>Dashboard</h1>
        <h2>Which marketplace features (filters, entrepreneurship, messaging) are used the most and the least?</h2>
        <canvas id="barChart" width="400" height="200"></canvas>
        <script>
            const ctx = document.getElementById('barChart').getContext('2d');
            const chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: %s,
                    datasets: [{
                        label: 'Feature Usage',
                        data: %s,
                        backgroundColor: 'rgba(54, 162, 235, 0.6)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
        </script>
    </body>
    </html>
    """ % (labels, values)

    return html