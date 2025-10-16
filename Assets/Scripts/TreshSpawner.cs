using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TreshSpawner : MonoBehaviour
{
    public static TreshSpawner Instance;
    public GameObject[] objectPrefab;
    public float botSpawnOffset = 2f; 
    public Transform Parent;
    private void Start()
    {
        Instance = this;
    }
    public void Spawn()
    {
        Camera cam = Camera.main;
        float camWidth = cam.orthographicSize * 2f * cam.aspect;
        float botY = cam.transform.position.y - cam.orthographicSize + botSpawnOffset;
        switch (PlayerPrefs.GetInt("Location"))
        {
            case 0:
                Instantiate(objectPrefab[Random.Range(0,4)], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), Random.Range(botY-1,botY+1), 0),Quaternion.Euler(0, 0, Random.Range(0, 360)),Parent);
                break;
            case 1:
                Instantiate(objectPrefab[Random.Range(4,7)], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), Random.Range(botY-1,botY+1), 0),Quaternion.Euler(0, 0, Random.Range(0, 360)),Parent);
                break;
            case 2:
                Instantiate(objectPrefab[Random.Range(7,10)], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), Random.Range(botY-1,botY+1), 0),Quaternion.Euler(0, 0, Random.Range(0, 360)),Parent);
                break;
            case 3:
                Instantiate(objectPrefab[Random.Range(10,14)], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), Random.Range(botY-1,botY+1), 0),Quaternion.Euler(0, 0, Random.Range(0, 360)),Parent);
                break;
        }
    }
}
