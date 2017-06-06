using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof (Camera))]
[AddComponentMenu("Effects/Clouds")]
public class Clouds : SceneViewFilter
{
	public Shader CloudShader;
	public float MinHeight = 0.0f;
	public float MaxHeight = 5.0f;
    public float FadeDist = 2;
    public float Scale = 5;

	public Texture ValueNoiseTable;

	public Transform Sun;

	private Camera _Cam;

	public Material Material {
		get {
			if(_Material == null && CloudShader != null) {
				Debug.Log("Creating Shader");
				_Material = new Material(CloudShader);
                _Material.hideFlags = HideFlags.HideAndDontSave;
			}

			if(_Material != null && CloudShader == null) {
				Debug.Log("Shader Deleted");
				DestroyImmediate(_Material);
			}

			if(_Material != null && CloudShader != null && CloudShader != _Material.shader) {
				Debug.Log("Shader Changed");
				DestroyImmediate(_Material);
				_Material = new Material(CloudShader);
                _Material.hideFlags = HideFlags.HideAndDontSave;
			}

			return _Material;
		}
	}
	private Material _Material;

	void Start() {
		if (_Material)
            DestroyImmediate(_Material);
	}

	[ImageEffectOpaque]
	void OnRenderImage (RenderTexture source, RenderTexture destination) {
		if(Material == null || ValueNoiseTable == null)
		{
            Graphics.Blit (source, destination);
            return;
        }

        if(_Cam == null)
        	_Cam = GetComponent<Camera>();

        Material.SetTexture("_ValueNoise", ValueNoiseTable);

		if(Sun != null) {
            RenderSettings.skybox.SetVector("_SunDir", -Sun.forward);
            Material.SetVector("_SunDir", -Sun.forward);
        }
        else
        {
            RenderSettings.skybox.SetVector("_SunDir", Vector3.up);
            Material.SetVector("_SunDir", 
                Vector3.up);
        }
			
		Material.SetFloat("_MinHeight", MinHeight);
		Material.SetFloat("_MaxHeight", MaxHeight);
        Material.SetFloat("_FadeDist", FadeDist);
        Material.SetFloat("_Scale", Scale);

		Material.SetMatrix("_FrustumCornersWS", GetFrustumCorners(_Cam));
        Material.SetMatrix("_CameraInvViewMatrix", _Cam.cameraToWorldMatrix);
        Material.SetVector ("_CameraWS", _Cam.transform.position);

        CustomGraphicsBlit(source, destination, Material, 0);
    }

    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }

    static void CustomGraphicsBlit (RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
	{
        RenderTexture.active = dest;

        fxMaterial.SetTexture ("_MainTex", source);

        GL.PushMatrix ();
        GL.LoadOrtho ();

        fxMaterial.SetPass (passNr);

        GL.Begin (GL.QUADS);

        GL.MultiTexCoord2 (0, 0.0f, 0.0f);
        GL.Vertex3 (0.0f, 0.0f, 3.0f); // BL

        GL.MultiTexCoord2 (0, 1.0f, 0.0f);
        GL.Vertex3 (1.0f, 0.0f, 2.0f); // BR

        GL.MultiTexCoord2 (0, 1.0f, 1.0f);
        GL.Vertex3 (1.0f, 1.0f, 1.0f); // TR

        GL.MultiTexCoord2 (0, 0.0f, 1.0f);
        GL.Vertex3 (0.0f, 1.0f, 0.0f); // TL

        GL.End ();
        GL.PopMatrix ();
    }

    void OnDrawGizmos()
    {
        if (_Cam == null)
            return;

        Gizmos.color = Color.green;

        Matrix4x4 corners = GetFrustumCorners(_Cam);
        Vector3 pos = _Cam.transform.position;

        for (int x = 0; x < 4; x++)
        {
            corners.SetRow(x, _Cam.cameraToWorldMatrix * corners.GetRow(x));
            Gizmos.DrawLine(pos, pos + (Vector3)(corners.GetRow(x)));
        }

        /*
        // UNCOMMENT TO DEBUG RAY DIRECTIONS
        Gizmos.color = Color.red;
        int n = 10; // # of intervals
        for (int x = 1; x < n; x++) {
            float i_x = (float)x / (float)n;
            var w_top = Vector3.Lerp(corners.GetRow(0), corners.GetRow(1), i_x);
            var w_bot = Vector3.Lerp(corners.GetRow(3), corners.GetRow(2), i_x);
            for (int y = 1; y < n; y++) {
                float i_y = (float)y / (float)n;
                
                var w = Vector3.Lerp(w_top, w_bot, i_y).normalized;
                Gizmos.DrawLine(pos + (Vector3)w, pos + (Vector3)w * 1.2f);
            }
        }
        */
    }

    protected virtual void OnDisable()
    {
        if (_Material)
            DestroyImmediate(_Material);
    }
}
