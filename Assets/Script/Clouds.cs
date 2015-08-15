using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof (Camera))]
[AddComponentMenu("Effects/Clouds")]
public class Clouds : MonoBehaviour {
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
            Material.SetVector("_SunDir", Vector3.up);
        }
			
		Material.SetFloat("_MinHeight", MinHeight);
		Material.SetFloat("_MaxHeight", MaxHeight);
        Material.SetFloat("_FadeDist", FadeDist);
        Material.SetFloat("_Scale", Scale);

		Material.SetMatrix("_FrustumCornersWS", GetFrustumCorners(_Cam));
		Material.SetVector ("_CameraWS", _Cam.transform.position);

        CustomGraphicsBlit(source, destination, Material, 0);
    }

    private Matrix4x4 GetFrustumCorners(Camera cam) {
		Transform camtr = cam.transform;
		float camNear = cam.nearClipPlane;
		float camFar = cam.farClipPlane;
		float camFov = cam.fieldOfView;
		float camAspect = cam.aspect;

    	Matrix4x4 frustumCorners = Matrix4x4.identity;

		float fovWHalf = camFov * 0.5f;

		Vector3 toRight = camtr.right * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad) * camAspect;
		Vector3 toTop = camtr.up * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad);

		Vector3 topLeft = (camtr.forward * camNear - toRight + toTop);
		float camScale = topLeft.magnitude * camFar/camNear;

	    topLeft.Normalize();
		topLeft *= camScale;

		Vector3 topRight = (camtr.forward * camNear + toRight + toTop);
	    topRight.Normalize();
		topRight *= camScale;

		Vector3 bottomRight = (camtr.forward * camNear + toRight - toTop);
	    bottomRight.Normalize();
		bottomRight *= camScale;

		Vector3 bottomLeft = (camtr.forward * camNear - toRight - toTop);
	    bottomLeft.Normalize();
		bottomLeft *= camScale;

	    frustumCorners.SetRow (0, topLeft);
	    frustumCorners.SetRow (1, topRight);
	    frustumCorners.SetRow (2, bottomRight);
	    frustumCorners.SetRow (3, bottomLeft);

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

    void OnDrawGizmos() {
        if (_Cam == null)
            return;
    	Transform camtr = _Cam.transform;
		float camNear = _Cam.nearClipPlane;
		float camFar = _Cam.farClipPlane;
		float camFov = _Cam.fieldOfView;
		float camAspect = _Cam.aspect;


		float fovWHalf = camFov * 0.5f;

		Vector3 toRight = camtr.right * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad) * camAspect;
		Vector3 toTop = camtr.up * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad);

		Vector3 topLeft = (camtr.forward * camNear - toRight + toTop);
		float camScale = topLeft.magnitude * camFar/camNear;

	    topLeft.Normalize();
		topLeft *= camScale;

		Vector3 topRight = (camtr.forward * camNear + toRight + toTop);
	    topRight.Normalize();
		topRight *= camScale;

		Vector3 bottomRight = (camtr.forward * camNear + toRight - toTop);
	    bottomRight.Normalize();
		bottomRight *= camScale;

		Vector3 bottomLeft = (camtr.forward * camNear - toRight - toTop);
	    bottomLeft.Normalize();
		bottomLeft *= camScale;

		Gizmos.color = Color.green;
    	Gizmos.DrawLine(transform.position, transform.position+topLeft);
    	Gizmos.DrawLine(transform.position, transform.position+topRight);
    	Gizmos.DrawLine(transform.position, transform.position+bottomLeft);
    	Gizmos.DrawLine(transform.position, transform.position+bottomRight);
    }

	protected virtual void OnDisable()
    {
        if (_Material)
            DestroyImmediate(_Material);
    }
}
