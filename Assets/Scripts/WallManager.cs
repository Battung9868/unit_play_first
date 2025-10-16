using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WallManager : MonoBehaviour
{
    public BoxCollider2D topWall;
    public BoxCollider2D bottomWall;
    public BoxCollider2D leftWall;
    public BoxCollider2D rightWall;

    void Start()
    {
        PositionWalls();
    }

    void PositionWalls()
    {
        Camera cam = Camera.main;

        float camHeight = 2f * cam.orthographicSize;
        float camWidth = camHeight * cam.aspect;

        float thickness = 1f; 

        topWall.size = new Vector2(camWidth, thickness);
        topWall.offset = Vector2.zero;
        topWall.transform.position = new Vector3(cam.transform.position.x, cam.transform.position.y + camHeight / 2 + thickness / 2, 0);

        bottomWall.size = new Vector2(camWidth, thickness);
        bottomWall.offset = Vector2.zero;
        bottomWall.transform.position = new Vector3(cam.transform.position.x, cam.transform.position.y - camHeight / 2 - thickness / 2, 0);

        leftWall.size = new Vector2(thickness, camHeight);
        leftWall.offset = Vector2.zero;
        leftWall.transform.position = new Vector3(cam.transform.position.x - camWidth / 2 - thickness / 2, cam.transform.position.y, 0);

        rightWall.size = new Vector2(thickness, camHeight);
        rightWall.offset = Vector2.zero;
        rightWall.transform.position = new Vector3(cam.transform.position.x + camWidth / 2 + thickness / 2, cam.transform.position.y, 0);
    }
}
