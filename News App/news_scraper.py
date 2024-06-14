import requests
from bs4 import BeautifulSoup
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, text

# Function to fetch news from BBC
def fetch_bbc_news():
    url = 'https://www.bbc.com/news'
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')

    sections = soup.select('section.sc-52c2b1e7-1')

    articles = []

    for section in sections:
        for article in section.find_all('h2', class_='sc-4fedabc7-3 zTZri'):
            headline = article.text.strip()
            category_tag = section.find('span', class_='sc-ec7fe2bd-2 bLHjE')
            category = category_tag.text.strip() if category_tag else 'General'
            link_tag = section.find('a', class_='sc-2e6baa30-0 gILusN')
            link = link_tag['href'] if link_tag else '#'
            articles.append({
                'headline': headline,
                'category': category,
                'link': link
            })

    return articles

# Function to store news in SQLite database
def store_news_in_db(articles):
    engine = create_engine('sqlite:///news.db')
    metadata = MetaData()

    # Define the news table
    news_table = Table('news', metadata,
        Column('id', Integer, primary_key=True),
        Column('headline', String),
        Column('category', String),
        Column('link', String)
    )

    # Create the table if it doesn't exist
    metadata.create_all(engine)

    with engine.connect() as connection:
        # Get the current count of articles
        result = connection.execute(text("SELECT COUNT(*) FROM news"))
        current_count = result.scalar()

        # Calculate the number of articles to delete
        num_articles_to_delete = (current_count + len(articles)) - 100

        if num_articles_to_delete > 0:
            # Delete the required number of oldest articles
            connection.execute(text(f"DELETE FROM news WHERE id IN (SELECT id FROM news ORDER BY id LIMIT {num_articles_to_delete})"))

        # Insert new articles into the table
        for article in articles:
            insert_statement = news_table.insert().values(
                headline=article['headline'],
                category=article['category'],
                link=article['link']
            )
            connection.execute(insert_statement)
        connection.commit()  # Ensure the transaction is committed

# Function to read and print news from the database
def news_reader():
    engine = create_engine('sqlite:///news.db')

    with engine.connect() as connection:
        result = connection.execute(text("SELECT * FROM news"))

        for row in result:
            print(f"ID: {row[0]}")
            print(f"Headline: {row[1]}")
            print(f"Category: {row[2]}")
            print(f"Link: {row[3]}")
            print('-' * 80)

def main():
    articles = fetch_bbc_news()
    store_news_in_db(articles)
    print("News articles have been stored in the database.")

    print("\nReading news from the database:\n")
    news_reader()

if __name__ == '__main__':
    main()
