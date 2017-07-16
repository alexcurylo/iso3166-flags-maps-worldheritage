import csv, json
headers = ['unique_number', 'id_no', 'name_en', 'date_inscribed', 'category', 'name_en']
data = []

with open('data.csv', 'r') as f:
    csvreader = csv.DictReader(f)
    rows = [row for row in csvreader]
    for row in rows:
        for key,value in row.iteritems():
            row[key] = value
        data.append(row)

seventies = []
eighties = []
nineties = []
aughties = []
teensies = []
for each in data:
    each_date = int(each['date_inscribed'])
    if each_date > 1969 and each_date < 1980:
        seventies.append(each)
    if each_date > 1979 and each_date < 1990:
        eighties.append(each)
    if each_date > 1989 and each_date < 2000:
        nineties.append(each)
    if each_date > 1999 and each_date < 2010:
        aughties.append(each)
    if each_date > 2009 and each_date < 2020:
        teensies.append(each)

with open('seventies.json', 'w') as f:
    f.write(json.dumps(seventies))
    f.close()
with open('eighties.json', 'w') as f:
    f.write(json.dumps(eighties))
    f.close()
with open('nineties.json', 'w') as f:
    f.write(json.dumps(nineties))
    f.close()
with open('aughties.json', 'w') as f:
    f.write(json.dumps(aughties))
    f.close()
with open('teensies.json', 'w') as f:
    f.write(json.dumps(teensies))
    f.close()

with open('data.json', 'w') as f:
    f.write(json.dumps(data))
    f.close()