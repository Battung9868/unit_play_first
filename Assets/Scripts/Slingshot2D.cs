using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.Tracing;
using UnityEngine;

public class Slingshot2D : MonoBehaviour
{
    [SerializeField] private float maxDragDistance;
    [SerializeField] private float launchForce;
    [SerializeField] private int trajectoryPoints;
    [SerializeField] private float timeStep;
    [SerializeField] private GameObject dotPrefab;

    private Vector2 startPosition;
    private Vector2 endPosition;
    private Rigidbody2D rb2d;
    private bool isDragging = false;
    private GameObject[] dots; 
    private GameObject colTreshBox;
    private AudioSource tochSound;

    void Start()
    {
        tochSound = GetComponent<AudioSource>();
        rb2d = GetComponent<Rigidbody2D>();
        startPosition = transform.position;
        dots = new GameObject[trajectoryPoints];
    }

    void OnMouseDown()
    {
        isDragging = true;
        rb2d.isKinematic = true;
    }

    void OnMouseDrag()
    {
        if (!isDragging) return;

        Vector3 mouseScreenPos = Input.mousePosition;
        mouseScreenPos.z = Camera.main.nearClipPlane;
        Vector3 mouseWorldPos3D = Camera.main.ScreenToWorldPoint(mouseScreenPos);
        Vector2 mousePos = new Vector2(mouseWorldPos3D.x, mouseWorldPos3D.y);

        Vector2 toMouse = startPosition - mousePos;
        float dragDistance = Mathf.Min(toMouse.magnitude, maxDragDistance);
        Vector2 dragVector = toMouse.normalized * dragDistance;

        endPosition = startPosition - dragVector;

        DrawTrajectory(mousePos);
    }

    void OnMouseUp()
    {
        if (!isDragging) return;

        isDragging = false;
        rb2d.isKinematic = false;

        rb2d.angularVelocity = Random.Range(-180, 180); 

        Vector3 mouseScreenPos = Input.mousePosition;
        mouseScreenPos.z = Camera.main.nearClipPlane;
        Vector3 mouseWorldPos3D = Camera.main.ScreenToWorldPoint(mouseScreenPos);
        Vector2 mousePos = new Vector2(mouseWorldPos3D.x, mouseWorldPos3D.y);

        Vector2 launchDirection = (startPosition - mousePos).normalized;
        float force = Vector2.Distance(startPosition, endPosition) * launchForce;
        rb2d.AddForce(launchDirection * force, ForceMode2D.Impulse);

        ClearTrajectory();
    }

    void DrawTrajectory(Vector2 mousePos)
    {
        ClearTrajectory();

        Vector2 velocity = (startPosition - mousePos).normalized * (Vector2.Distance(startPosition, endPosition) * launchForce / rb2d.mass);
        Vector2 currentPos = transform.position;

        for (int i = 0; i < trajectoryPoints; i++)
        {
            dots[i] = Instantiate(dotPrefab, new Vector3(currentPos.x, currentPos.y, 0), Quaternion.identity);

            float scale = Mathf.Lerp(0.2f, 0.01f, (float)i / (trajectoryPoints - 1));
            dots[i].transform.localScale = new Vector3(scale, scale, 1);

            velocity += Physics2D.gravity * timeStep;
            currentPos += velocity * timeStep;
        }
    }

    void ClearTrajectory()
    {
        for (int i = 0; i < dots.Length; i++)
        {
            if (dots[i] != null)
            {
                Destroy(dots[i]);
            }
        }
    }
    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.tag == "Treshbox")
        {
            colTreshBox = collision.gameObject;
            this.gameObject.GetComponent<PolygonCollider2D>().enabled = false;
            Settings.Instance.PlayTreshBoxSound();
            StartCoroutine(AnimateAndThenOtherAction());
            Settings.Instance.ChangeScore();
            switch (this.gameObject.tag)
            {
                case "Can":
                    PlayerPrefs.SetInt("Can", PlayerPrefs.GetInt("Can") + 1);
                    break;
                case "Paper":
                    PlayerPrefs.SetInt("Paper", PlayerPrefs.GetInt("Paper") + 1);
                    break;
                case "Plastic":
                    PlayerPrefs.SetInt("Plastic", PlayerPrefs.GetInt("Plastic") + 1);
                    break;
            }
        }
        if (collision.tag == "Down")
        {
            Settings.Instance.ChangeHp();
            TreshSpawner.Instance.Spawn();
            Destroy(this.gameObject,1f);
        }
    }
    private void OnCollisionEnter2D(Collision2D collision)
    {
        tochSound.Play();
    }
    IEnumerator AnimateAndThenOtherAction()
    {
        Vector3 initialRotation = transform.eulerAngles;
        Vector3 initialScale = transform.localScale;

        rb2d.gravityScale = 0;
        rb2d.velocity = Vector3.zero;     
        rb2d.angularVelocity = 0;

        Vector3 targetRotation = initialRotation + new Vector3(0,0,1) * 360f;
        Vector3 targetScale = initialScale * 0.1f;  

        float elapsedTime = 0f;

        while (elapsedTime < 1f)
        {
            elapsedTime += Time.deltaTime;
            float progress = elapsedTime / 1f;

            transform.eulerAngles = Vector3.Lerp(initialRotation, targetRotation, progress);
            transform.localScale = Vector3.Lerp(initialScale, targetScale, progress);

            yield return null; 
        }
        
        TreshboxSpawner.Instance.HandleObjectHit(colTreshBox);
        TreshSpawner.Instance.Spawn();
        Destroy(this.gameObject);
    }
}
