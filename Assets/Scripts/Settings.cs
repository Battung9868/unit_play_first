using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class Settings : MonoBehaviour
{
    public static Settings Instance;
    [SerializeField] private Sprite[] background;
    [SerializeField] private Image ImageBackground;
    [SerializeField] private Image[] Hearts;
    [SerializeField] private Sprite[] sprHearts;
    [SerializeField] private GameObject EndPanel;
    [SerializeField] private TMP_Text txtScore, txtPlastic, txtCan, txtPaper, txtEndScore;
    [SerializeField] private Sprite[] sprSound;
    [SerializeField] private Image[] butSound;
    [SerializeField] private AudioSource treshbox, heartsSound;

    private int currentHp;
    private int currentScore;


    private void Start()
    {
        Instance = this;
        currentHp = 3;
        CheckSound();
    }
    public void ChangeLocation(int i)
    {
        PlayerPrefs.SetInt("Location", i);
    }
    public void StartGame()
    {
        Restart();
        TreshboxSpawner.Instance.RestartTreshBox();
        ImageBackground.sprite = background[PlayerPrefs.GetInt("Location")];
        TreshSpawner.Instance.Spawn();
        TreshboxSpawner.Instance.SpawnInitialObjects();
    }
    public void ChangeHp()
    {
        currentHp--;
        CheckStatus();
    }
    private void CheckStatus()
    {
        switch (currentHp)
        {
            case 3:
                for (int i = 0; i < 3; i++)
                {
                    Hearts[i].sprite = sprHearts[1];
                }
                break;
            case 2:
                Hearts[0].sprite = sprHearts[0];
                Hearts[0].GetComponent<ParticleSystem>().Play();
                heartsSound.Play();
                break;
            case 1:
                Hearts[1].sprite = sprHearts[0];
                Hearts[1].GetComponent<ParticleSystem>().Play();
                heartsSound.Play();
                break;
            case 0:
                Hearts[2].sprite = sprHearts[0];
                Hearts[2].GetComponent<ParticleSystem>().Play();
                heartsSound.Play();
                EndGame();
                break;

        }
    }
    public void ChangeScore()
    {
        currentScore++;
        UpdateScore();
    }
    private void UpdateScore()
    {
        txtScore.text = currentScore.ToString();
    }
    private void EndGame()
    {
        EndPanel.SetActive(true);
        txtEndScore.text = currentScore.ToString();
    }
    public void UpdateAchievement()
    {
        txtPlastic.text = $"You collected <color=green>{PlayerPrefs.GetInt("Plastic")}</color> plastic bottles — that's like <color=green>saving {PlayerPrefs.GetInt("Plastic") / 5} liter of oil</color>";
        txtPaper.text = $"By recycling <color=green>{PlayerPrefs.GetInt("Paper")}</color> newspapers, you saved <color=green>{PlayerPrefs.GetInt("Paper") / 20} tree</color>";
        txtCan.text = $"By collecting <color=green>{PlayerPrefs.GetInt("Can")}</color> cans, you saved enough energy <color=green>to power a light bulb for {(PlayerPrefs.GetInt("Can") / 10) * 3} hours</color>";
    }
    public void MainMenu()
    {
        SceneManager.LoadScene(0);
    }
    public void ResetProgress()
    {
        PlayerPrefs.SetInt("Plastic", 0);
        PlayerPrefs.SetInt("Paper", 0);
        PlayerPrefs.SetInt("Can", 0);
    }
    public void Restart()
    {
        currentScore = 0;
        UpdateScore();
        currentHp = 3;
        CheckStatus();
    }
    public void SoundOnOff(int i)
    {
        PlayerPrefs.SetInt("Sound", i);
        CheckSound();
    }
    public void CheckSound()
    {
        if (PlayerPrefs.GetInt("Sound") == 1)
        {
            butSound[0].sprite = sprSound[1];
            butSound[1].sprite = sprSound[0];
            AudioListener.volume = 0f;
        }
        else
        {
            butSound[0].sprite = sprSound[0];
            butSound[1].sprite = sprSound[1];
            AudioListener.volume = 1f;
        }
    }
    public void PlayTreshBoxSound()
    {
        treshbox.Play();
    }
}
