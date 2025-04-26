from fastapi import FastAPI
from google.cloud import firestore
import os
from collections import defaultdict
from dotenv import load_dotenv
from fastapi.responses import HTMLResponse

load_dotenv()
app = FastAPI()

@app.get("/", response_class=HTMLResponse)
async def index():
    db = firestore.Client()

    # --- Feature usage ---
    logs_ref = db.collection('logs').where('type', '==', 'feature_usage')
    docs = logs_ref.stream()

    counts = {}
    for doc in docs:
        data = doc.to_dict()
        feature = data.get('feature', '')
        if feature.startswith('search'):
            feature = 'search_*'
        counts[feature] = counts.get(feature, 0) + 1

    labels = list(counts.keys())
    values = list(counts.values())
    if labels and values:
        labels, values = zip(*sorted(zip(labels, values), key=lambda x: x[1], reverse=True))
        labels = list(labels)
        values = list(values)

    # --- Performance stats ---
    response_logs_ref = db.collection('logs').where('type', '==', 'response_time')
    response_docs = response_logs_ref.stream()

    count = 0
    total_req_to_rec = 0
    total_req_to_show = 0
    total_proc_time = 0

    for doc in response_docs:
        try:
            data = doc.to_dict()
            requested_at = int(data.get('requested_at', 0))
            received_at = int(data.get('received_at', 0))
            showed_at = int(data.get('showed_at', 0))

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

    # --- Time spent per section ---
    session_logs_ref = db.collection('logs').where('type', '==', 'session_event')
    session_docs = session_logs_ref.stream()

    session_data = defaultdict(lambda: defaultdict(list))
    for doc in session_docs:
        data = doc.to_dict()
        user = data.get('user_id')
        section = data.get('section')
        event = data.get('event')
        timestamp = data.get('timestamp')

        if user and section and event and timestamp:
            session_data[user][section].append((event, int(timestamp)))

    section_durations = defaultdict(list)
    for user, sections in session_data.items():
        for section, events in sections.items():
            events.sort(key=lambda x: x[1])
            stack = []
            for event, ts in events:
                if event == "enter":
                    stack.append(ts)
                elif event == "exit" and stack:
                    enter_ts = stack.pop(0)
                    duration = ts - enter_ts
                    if 0 < duration < 60_000 * 60:
                        section_durations[section].append(duration)

    avg_section_time = {
        section: sum(times) / len(times)
        for section, times in section_durations.items() if times
    }
    sorted_section_times = sorted(avg_section_time.items(), key=lambda x: x[1], reverse=True)
    top_sections_time = sorted_section_times[:5]
    section_labels = [s[0] for s in top_sections_time]
    section_avg_times = [round(s[1] / 1000, 2) for s in top_sections_time]

    # --- Materials analysis ---
    products_ref = db.collection('products')
    products = products_ref.stream()

    material_counts = {}
    for product in products:
        data = product.to_dict()
        category = data.get('category')
        if category:
            material_counts[category] = material_counts.get(category, 0) + 1

    material_labels = list(material_counts.keys())
    material_values = list(material_counts.values())

    # --- Render HTML ---
    html = """
    <html>
    <head>
        <title>Dashboard</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            .container { display: flex; flex-wrap: wrap; }
            .chart-container, .stats-container { width: 50%%; padding: 20px; }
        </style>
    </head>
    <body>
        <h1>App Analytics Dashboard</h1>
        <div class="container">
            <div class="chart-container">
                <h2>Which marketplace features are used the most and the least?</h2>
                <canvas id="barChart"></canvas>
            </div>
            <div class="stats-container">
                <h2>Performance Metrics</h2>
                <p><b>Avg Requested to Received:</b> %d ms</p>
                <p><b>Avg Requested to Showed:</b> %d ms</p>
                <p><b>Avg Processing Time:</b> %d ms</p>
            </div>
            <div class="chart-container">
                <h2>Where Users Spend the Most Time</h2>
                <canvas id="timeChart"></canvas>
            </div>
            <div class="chart-container">
                <h2>Which materials/type of materials are being sold the most?</h2>
                <canvas id="materialChart"></canvas>
            </div>
        </div>
        <script>
            new Chart(document.getElementById('barChart'), {
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
                options: { scales: { y: { beginAtZero: true } } }
            });

            new Chart(document.getElementById('timeChart'), {
                type: 'bar',
                data: {
                    labels: %s,
                    datasets: [{
                        label: 'Avg Time Spent (sec)',
                        data: %s,
                        backgroundColor: 'rgba(255, 159, 64, 0.6)',
                        borderColor: 'rgba(255, 159, 64, 1)',
                        borderWidth: 1
                    }]
                },
                options: { scales: { y: { beginAtZero: true } } }
            });

            new Chart(document.getElementById('materialChart'), {
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
                options: { scales: { y: { beginAtZero: true } } }
            });
        </script>
    </body>
    </html>
    """ % (
        avg_req_to_rec, avg_req_to_show, avg_proc_time,
        labels, values,
        section_labels, section_avg_times,
        material_labels, material_values
    )

    return HTMLResponse(content=html)