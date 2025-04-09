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
    
    # Parte del código para la pregunta de negocio "Which marketplace features are used the most and the least?"
    logs_ref = db.collection('logs').where('type', '==', 'feature_usage')
    docs = logs_ref.stream()
    
    counts = {}
    for doc in docs:
        data = doc.to_dict()
        feature = data.get('feature')
        if feature.startswith('search'):
            feature = 'search_*'
        counts[feature] = counts.get(feature, 0) + 1

    response_logs_ref = db.collection('logs').where('type', '==', 'response_time')
    response_docs = response_logs_ref.stream()

    count = 0
    total_req_to_rec = 0
    total_req_to_show = 0
    total_proc_time = 0

    for doc in response_docs:
        try:
            data = doc.to_dict()
            requested_at = int(data.get('requested_at'))
            received_at = int(data.get('received_at'))
            showed_at = int(data.get('showed_at'))

            req_to_rec = received_at - requested_at
            req_to_show = showed_at - requested_at
            proc_time = showed_at - received_at

            if req_to_rec > 0 and req_to_show > 0 and proc_time > 0:
                total_req_to_rec += req_to_rec
                total_req_to_show += req_to_show
                total_proc_time += proc_time
                count += 1
        except:
            continue

    avg_req_to_rec = total_req_to_rec / count if count else 0
    avg_req_to_show = total_req_to_show / count if count else 0
    avg_proc_time = total_proc_time / count if count else 0

    # Parte del código para la pregunta de negocio "Which materials/type of materials are being sold the most?"
    products_ref = db.collection('products')
    products = products_ref.stream()

    material_counts = {}
    for product in products:
        data = product.to_dict()
        category = data.get('category')  # Usamos la categoría para el análisis

        if category:
            material_counts[category] = material_counts.get(category, 0) + 1

    # Generar los labels y values para el gráfico
    labels = list(counts.keys())
    values = list(counts.values())

    material_labels = list(material_counts.keys())
    material_values = list(material_counts.values())

    html = """
    <html>
    <head>
        <title>Dashboard</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            .container { display: flex; }
            .chart-container { width: 50%%; }
            .stats-container { width: 50%%; padding: 20px; }
        </style>
    </head>
    <body>
        <h1>Dashboard</h1>
        <div class="container">
            <div class="chart-container">
                <h2>Which marketplace features (filters, entrepreneurship, messaging) are used the most and the least?</h2>
                <canvas id="barChart" width="300" height="150"></canvas>
            </div>
            <div class="stats-container">
                <h2>How long does it take to request, receive, and show the product results?</h2>
                <p>Avg Requested to Received: %d ms</p>
                <p>Avg Requested to Showed: %d ms</p>
                <p>Avg Processing Time: %d ms</p>
            </div>
            <div class="container">
                <div class="chart-container">
                    <h2>Which materials/type of materials are being sold the most?</h2>
                    <canvas id="materialChart" width="300" height="150"></canvas>
                </div>
            </div>
        </div>
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

            const materialCtx = document.getElementById('materialChart').getContext('2d');
            const materialChart = new Chart(materialCtx, {
                type: 'bar',
                data: {
                    labels: %s,
                    datasets: [{
                        label: 'Material Usage',
                        data: %s,
                        backgroundColor: 'rgba(255, 99, 132, 0.6)',
                        borderColor: 'rgba(255, 99, 132, 1)',
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
    """ % (avg_req_to_rec, avg_req_to_show, avg_proc_time, labels, values, material_labels, material_values)

    return html