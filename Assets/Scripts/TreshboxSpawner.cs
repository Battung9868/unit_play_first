using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class TreshboxSpawner : MonoBehaviour
{
    public static TreshboxSpawner Instance;
    public GameObject[] objectPrefab;
    public float minMoveDistance = 4f;  
    public float maxMoveDistance = 7f;  
    public float moveDuration = 0.5f;   
    public float topSpawnOffset = 1f;   
    private List<GameObject> activeObjects = new List<GameObject>();
    public Transform Parent;

    private bool isMoving = false;

    void Start()
    {
        Instance = this;
    }

    public void SpawnInitialObjects()
    {
        Camera cam = Camera.main;
        float camWidth = cam.orthographicSize * 2f * cam.aspect;
        float topY = cam.transform.position.y + cam.orthographicSize + topSpawnOffset;

        GameObject lowerObj = Instantiate(objectPrefab[PlayerPrefs.GetInt("Location")], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), topY - 5f, 0), Quaternion.identity, Parent);  // Примерная средняя высота
        activeObjects.Add(lowerObj);

        GameObject upperObj = Instantiate(objectPrefab[PlayerPrefs.GetInt("Location")], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), topY, 0), Quaternion.identity, Parent);
        activeObjects.Add(upperObj);
    }

    public void HandleObjectHit(GameObject hitObject)
    {
        if (activeObjects.Contains(hitObject))
        {
            activeObjects.Remove(hitObject);
            Destroy(hitObject);
            CleanUpAndSpawnNewIfNeeded();
            MoveDownBySignal();
        }
    }

    public void MoveDownBySignal()
    {
        if (isMoving) return; 
        float currentMoveDistance = Random.Range(minMoveDistance, maxMoveDistance);
        StartCoroutine(MoveObjectsDown(currentMoveDistance));
    }

    IEnumerator MoveObjectsDown(float distance)
    {
        isMoving = true;

        float elapsed = 0f;
        float duration = moveDuration;

        List<Vector3> startPositions = new List<Vector3>();
        foreach (var obj in activeObjects)
            startPositions.Add(obj.transform.position);

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / duration);

            for (int i = 0; i < activeObjects.Count; i++)
            {
                Vector3 startPos = startPositions[i];
                activeObjects[i].transform.position = Vector3.Lerp(startPos, startPos + Vector3.down * distance, t);
            }

            yield return null;
        }

        isMoving = false;
    }

    public void CleanUpAndSpawnNewIfNeeded()
    {
        List<GameObject> toRemove = new List<GameObject>();

        foreach (var rem in toRemove)
        {
            activeObjects.Remove(rem);
            Destroy(rem);
        }

        while (activeObjects.Count < 2)
        {
            SpawnNewAtTop();
        }

    }

    void SpawnNewAtTop()
    {
        Camera cam = Camera.main;
        float camWidth = cam.orthographicSize * 2f * cam.aspect;
        float topY = cam.transform.position.y + cam.orthographicSize + topSpawnOffset;

        GameObject newObj = Instantiate(objectPrefab[PlayerPrefs.GetInt("Location")], new Vector3(Random.Range(-camWidth / 2.5f, camWidth / 2.5f), topY + 5f, 0), Quaternion.identity, Parent);
        activeObjects.Add(newObj);
    }
    public void RestartTreshBox()
    {
        if (Parent.childCount > 0)
        {
            Destroy(Parent.GetChild(2).gameObject);
            Destroy(Parent.GetChild(1).gameObject);
            Destroy(Parent.GetChild(0).gameObject);
        }
        activeObjects.Clear();
    }
}
