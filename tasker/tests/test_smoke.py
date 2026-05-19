def test_landing_view_returns_200(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"alive" in response.content
